"""Run agno teams and translate outputs to supervisor responses."""

from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
import json
from typing import Any, Dict, List, Optional

from agno.agent import (
    RunCompletedEvent as AgentRunCompletedEvent,
    RunContentEvent as AgentRunContentEvent,
    RunErrorEvent as AgentRunErrorEvent,
    RunStartedEvent as AgentRunStartedEvent,
    RunPausedEvent as AgentRunPausedEvent,
    RunContinuedEvent as AgentRunContinuedEvent,
    ToolCallCompletedEvent,
    ToolCallStartedEvent,
)
from agno.team import (
    RunCompletedEvent as TeamRunCompletedEvent,
    RunContentEvent as TeamRunContentEvent,
    RunStartedEvent as TeamRunStartedEvent,
    RunErrorEvent as TeamRunErrorEvent,
    ToolCallCompletedEvent as TeamToolCallCompletedEvent,
    ToolCallStartedEvent as TeamToolCallStartedEvent,
)
from agno.run.agent import RunOutput, RunStatus
from agno.team import Team
from agno.team.team import TeamRunOutput

from app.json_render import JSON_RENDER_SPEC_FENCE_CLOSE, JSON_RENDER_SPEC_FENCE_OPEN, JsonRenderParser
from app.models.internal import CoordinationContext
from app.schemas.agent_run import SupervisorRunResponse, SupervisorMetadata, AgentExecutionResult
from app.runtime.supervisor.streaming.workflow_events import WorkflowEventEmitter
from app.core.logging import get_logger

from .builder import BuiltTeam


@dataclass
class TeamRunResult:
    """Container for final team execution artifacts."""

    output: TeamRunOutput
    agent_results: List[AgentExecutionResult]
    total_time: float


@dataclass
class MemberStreamState:
    """Track streaming metadata for an individual team member."""

    member_id: str
    name: str
    role: Optional[str]
    run_id: str
    chunk_index: int = 0


@dataclass
class JsonRenderStreamFilter:
    """Split mixed stream content into text and json-render patch lines."""

    active: bool = False
    in_spec_fence: bool = False
    buffering: bool = False
    line_buffer: str = ""
    patch_emitted: bool = False

    @staticmethod
    def _parse_patch_line(line: str) -> Optional[Dict[str, Any]]:
        if not line or not line.startswith("{"):
            return None
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError:
            return None
        if not isinstance(parsed, dict):
            return None
        op = parsed.get("op")
        path = parsed.get("path")
        if not isinstance(op, str) or not isinstance(path, str) or not path.startswith("/"):
            return None
        return parsed

    def _process_complete_line(self, line: str) -> tuple[str, List[Dict[str, Any]]]:
        trimmed = line.strip()

        if not self.in_spec_fence and trimmed.startswith(JSON_RENDER_SPEC_FENCE_OPEN):
            self.in_spec_fence = True
            return "", []
        if self.in_spec_fence and trimmed == JSON_RENDER_SPEC_FENCE_CLOSE:
            self.in_spec_fence = False
            return "", []

        patch = self._parse_patch_line(trimmed)
        if patch is not None:
            self.patch_emitted = True
            return "", [patch]

        if self.in_spec_fence:
            return "", []

        if not line:
            return "\n", []
        return f"{line}\n", []

    def filter_chunk(self, chunk: str) -> tuple[str, List[Dict[str, Any]]]:
        """Return `(text_to_emit, patch_lines)` for a streamed chunk."""
        if not self.active:
            return chunk, []

        text_segments: List[str] = []
        patches: List[Dict[str, Any]] = []

        for ch in chunk:
            if ch == "\n":
                if self.buffering:
                    text_part, parsed_patches = self._process_complete_line(self.line_buffer)
                    if text_part:
                        text_segments.append(text_part)
                    if parsed_patches:
                        patches.extend(parsed_patches)
                    self.line_buffer = ""
                    self.buffering = False
                elif not self.in_spec_fence:
                    text_segments.append("\n")
                continue

            if not self.buffering and not self.line_buffer:
                if self.in_spec_fence or ch == "{" or ch == "`":
                    self.buffering = True
                    self.line_buffer = ch
                else:
                    text_segments.append(ch)
                continue

            if self.buffering:
                self.line_buffer += ch
            else:
                text_segments.append(ch)

        return "".join(text_segments), patches

    def flush(self) -> tuple[str, List[Dict[str, Any]]]:
        """Flush buffered text and final patch lines when stream ends."""
        if not self.active:
            return "", []

        text_segments: List[str] = []
        patches: List[Dict[str, Any]] = []

        if self.buffering and self.line_buffer:
            text_part, parsed_patches = self._process_complete_line(self.line_buffer)
            if text_part:
                text_segments.append(text_part)
            if parsed_patches:
                patches.extend(parsed_patches)

        self.line_buffer = ""
        self.buffering = False
        self.in_spec_fence = False

        return "".join(text_segments), patches


@dataclass
class StreamCollector:
    """Aggregate streaming artefacts while the team run progresses."""

    team_id: str
    team_name: str
    session_id: Optional[str]
    team_run_id: Optional[str] = None
    team_run_event: Optional[TeamRunCompletedEvent] = None
    final_member_event: Optional[AgentRunCompletedEvent] = None
    member_states: Dict[str, MemberStreamState] = field(default_factory=dict)
    member_completions: Dict[str, AgentRunCompletedEvent] = field(default_factory=dict)
    started_at: float = 0.0
    json_render_filter: JsonRenderStreamFilter = field(default_factory=JsonRenderStreamFilter)


class AgnoTeamRunner:
    """Execute agno teams with optional streaming support."""

    def __init__(self) -> None:
        self._logger = get_logger("runtime.supervisor.teams.runner")

    async def run(self, built_team: BuiltTeam, context: CoordinationContext) -> SupervisorRunResponse:
        start_time = time.time()
        output = await built_team.team.arun(context.message)
        total_time = time.time() - start_time

        agent_results = self._convert_member_responses(output.member_responses, context)
        final_content = output.get_content_as_string() if output.content is not None else ""

        metadata = SupervisorMetadata(
            total_execution_time=total_time,
            agents_consulted=len(agent_results),
            strategy_used="agno_team",
            team_id=context.team.id,
            consensus_achieved=None,
        )

        return SupervisorRunResponse(
            success=True,
            message="Team coordination completed",
            results=agent_results or None,
            content=final_content,
            metadata=metadata,
            error=None,
        )

    async def stream(
        self,
        built_team: BuiltTeam,
        context: CoordinationContext,
        workflow_events: WorkflowEventEmitter,
    ) -> TeamRunResult:
        start_time = time.time()

        team_id = str(context.team.id)
        team_name = context.team.name or "Supervisor Coordination Team"
        session_id = context.session_id

        collector = StreamCollector(team_id=team_id, team_name=team_name, session_id=session_id, started_at=start_time)
        ui_mode = context.ui_mode
        if ui_mode == "json_render":
            collector.json_render_filter.active = True

        async for event in built_team.team.arun(
            context.message,
            stream=True,
            stream_intermediate_steps=True,
            store_member_responses=True,
            debug=True,
            session_id=session_id,
            user_id=context.user_id,
        ):
            self._dispatch_stream_event(
                event=event,
                collector=collector,
                built_team=built_team,
                context=context,
                workflow_events=workflow_events,
            )

        total_time = time.time() - start_time

        agent_results = self._convert_completed_events(collector.member_completions, context)

        final_content = ""
        if collector.final_member_event is not None and collector.final_member_event.content:
            final_content = self._ensure_text(collector.final_member_event.content)
        elif collector.team_run_event is not None and collector.team_run_event.content:
            final_content = self._ensure_text(collector.team_run_event.content)

        if not final_content:
            self._logger.warning(
                "Result consolidation agent did not provide final content; falling back to aggregated outputs"
            )

        output = TeamRunOutput(
            content=final_content,
            member_responses=[self._event_to_run_output(evt) for evt in collector.member_completions.values()],
        )

        return TeamRunResult(
            output=output,
            agent_results=agent_results,
            total_time=total_time,
        )

    def _convert_member_responses(
        self,
        member_responses: Optional[List[RunOutput]],
        context: CoordinationContext,
    ) -> List[AgentExecutionResult]:
        if not member_responses:
            return []

        results: List[AgentExecutionResult] = []
        for response in member_responses:
            results.append(self._run_output_to_execution_result(response, context))
        return results

    @staticmethod
    def _ensure_text(value: Optional[Any]) -> str:
        if value is None:
            return ""
        if isinstance(value, str):
            return value
        return str(value)

    @staticmethod
    def _extract_tool_details(event: Any) -> tuple[str, Optional[str], Optional[dict], Optional[str]]:
        if hasattr(event, "tool_name"):
            return (
                getattr(event, "tool_name") or "tool",
                getattr(event, "tool_call_id", None),
                getattr(event, "tool_input", None),
                getattr(event, "tool_output", None),
            )

        tool = getattr(event, "tool", None)
        if tool is None:
            return "tool", None, None, None

        return (
            tool.tool_name or "tool",
            tool.tool_call_id,
            tool.tool_args,
            getattr(tool, "result", None),
        )

    def _dispatch_stream_event(
        self,
        *,
        event: Any,
        collector: StreamCollector,
        built_team: BuiltTeam,
        context: CoordinationContext,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        if isinstance(event, TeamRunStartedEvent):
            self._handle_team_run_started(event, collector, workflow_events, context)
        elif isinstance(event, TeamRunContentEvent):
            self._handle_team_run_content(event, collector, workflow_events)
        elif isinstance(event, TeamRunErrorEvent):
            self._handle_team_run_failed(event, collector, workflow_events)
        elif isinstance(event, TeamRunCompletedEvent):
            self._handle_team_run_completed(event, collector, workflow_events, context)
        elif isinstance(event, TeamToolCallStartedEvent):
            self._handle_team_tool_call_started(event, collector, built_team, workflow_events)
        elif isinstance(event, TeamToolCallCompletedEvent):
            self._handle_team_tool_call_completed(event, collector, built_team, workflow_events)
        elif isinstance(event, AgentRunStartedEvent):
            self._handle_member_run_started(event, collector, built_team, workflow_events)
        elif isinstance(event, AgentRunContentEvent):
            self._handle_member_run_content(event, collector, built_team, workflow_events)
        elif isinstance(event, AgentRunCompletedEvent):
            self._handle_member_run_completed(event, collector, built_team, workflow_events)
        elif isinstance(event, AgentRunPausedEvent):
            self._handle_member_run_paused(event, collector, built_team, workflow_events)
        elif isinstance(event, AgentRunContinuedEvent):
            self._handle_member_run_continued(event, collector, built_team, workflow_events)
        elif isinstance(event, AgentRunErrorEvent):
            self._handle_member_run_failed(event, collector, built_team, workflow_events)
        elif isinstance(event, ToolCallStartedEvent):
            self._handle_member_tool_call_started(event, collector, built_team, workflow_events)
        elif isinstance(event, ToolCallCompletedEvent):
            self._handle_member_tool_call_completed(event, collector, built_team, workflow_events)

    def _handle_team_run_started(
        self,
        event: TeamRunStartedEvent,
        collector: StreamCollector,
        workflow_events: WorkflowEventEmitter,
        context: CoordinationContext,
    ) -> None:
        collector.team_run_id = event.run_id

        workflow_events.emit_team_run_started(
            team_id=event.team_id or collector.team_id,
            team_name=event.team_name or collector.team_name,
            run_id=collector.team_run_id,
            session_id=event.session_id or collector.session_id,
            message_length=len(context.message),
        )

    def _handle_team_run_content(
        self,
        event: TeamRunContentEvent,
        collector: StreamCollector,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        collector.team_run_id = event.run_id or collector.team_run_id or uuid.uuid4().hex

        content = self._ensure_text(getattr(event, "content", ""))
        content, patches = collector.json_render_filter.filter_chunk(content)
        if patches:
            workflow_events.emit_json_render_update(
                patches=patches,
                team_id=event.team_id or collector.team_id,
            )

        if not content:
            return

        workflow_events.emit_team_run_content(
            team_id=event.team_id or collector.team_id,
            team_name=event.team_name or collector.team_name,
            run_id=collector.team_run_id,
            content=content,
            content_type=getattr(event, "content_type", "str") or "str",
            reasoning_content=getattr(event, "reasoning_content", None),
            is_intermediate=False,
        )

    def _handle_team_run_failed(
        self,
        event: TeamRunErrorEvent,
        collector: StreamCollector,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        collector.team_run_id = event.run_id or collector.team_run_id or uuid.uuid4().hex

        workflow_events.emit_team_run_failed(
            team_id=event.team_id or collector.team_id,
            team_name=event.team_name or collector.team_name,
            error=self._ensure_text(getattr(event, "error", None) or getattr(event, "content", None))
            or "Team run failed",
            run_id=collector.team_run_id,
        )

    def _handle_team_run_completed(
        self,
        event: TeamRunCompletedEvent,
        collector: StreamCollector,
        workflow_events: WorkflowEventEmitter,
        context: Optional[CoordinationContext] = None,
    ) -> None:
        collector.team_run_event = event
        collector.team_run_id = event.run_id or collector.team_run_id or uuid.uuid4().hex

        # Flush buffered text and patches before stream end.
        remaining, flushed_patches = collector.json_render_filter.flush()
        if remaining:
            workflow_events.emit_team_run_content(
                team_id=event.team_id or collector.team_id,
                team_name=event.team_name or collector.team_name,
                run_id=collector.team_run_id,
                content=remaining,
            )
        if flushed_patches:
            workflow_events.emit_json_render_update(
                patches=flushed_patches,
                team_id=event.team_id or collector.team_id,
            )

        content = self._ensure_text(getattr(event, "content", ""))
        total_time = max(0.0, time.time() - collector.started_at)

        # Parse fallback only when stream path did not emit any patch.
        ui_mode = getattr(context, "ui_mode", None) if context is not None else None
        if content and context is not None and ui_mode == "json_render" and not collector.json_render_filter.patch_emitted:
            try:
                json_render_result = JsonRenderParser().parse(content)
                self._logger.info(
                    "json-render parse result",
                    has_json_render=json_render_result.has_json_render,
                    is_valid=json_render_result.is_valid,
                    patch_count=len(json_render_result.patches),
                    validation_error=json_render_result.validation_error,
                )
                if json_render_result.has_json_render and json_render_result.patches:
                    workflow_events.emit_json_render_update(
                        patches=json_render_result.patches,
                        text_content=json_render_result.text_content or None,
                        team_id=event.team_id or collector.team_id,
                    )
                    content = json_render_result.text_content or content
                    try:
                        object.__setattr__(event, "content", content)
                    except (AttributeError, TypeError):
                        pass
            except Exception as exc:  # noqa: BLE001
                self._logger.warning("json-render parsing failed in team_run_completed", error=str(exc))

        workflow_events.emit_team_run_completed(
            team_id=event.team_id or collector.team_id,
            team_name=event.team_name or collector.team_name,
            run_id=collector.team_run_id,
            total_time=total_time,
            content_length=len(content) if content else None,
            content=content,
        )

    def _handle_team_tool_call_started(
        self,
        event: TeamToolCallStartedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(
            event=event,
            collector=collector,
            built_team=built_team,
            fallback_role="team",
        )
        tool_name, tool_call_id, tool_input, _ = self._extract_tool_details(event)

        workflow_events.emit_team_member_tool_call_started(
            team_id=event.team_id or collector.team_id,
            team_name=event.team_name or collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            tool_name=tool_name,
            member_role=state.role,
            tool_call_id=tool_call_id,
            tool_input=tool_input,
        )

    def _handle_team_tool_call_completed(
        self,
        event: TeamToolCallCompletedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(
            event=event,
            collector=collector,
            built_team=built_team,
            fallback_role="team",
        )
        tool_name, tool_call_id, tool_input, tool_output = self._extract_tool_details(event)

        workflow_events.emit_team_member_tool_call_completed(
            team_id=event.team_id or collector.team_id,
            team_name=event.team_name or collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            tool_name=tool_name,
            member_role=state.role,
            tool_call_id=tool_call_id,
            tool_input=tool_input,
            tool_output=tool_output or self._ensure_text(getattr(event, "content", None)),
        )

    def _handle_member_run_started(
        self,
        event: AgentRunStartedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        state.chunk_index = 0

        workflow_events.emit_team_member_started(
            team_id=collector.team_id,
            team_name=collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            member_role=state.role,
        )

    def _handle_member_run_content(
        self,
        event: AgentRunContentEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        content_chunk = self._ensure_text(getattr(event, "content", ""))
        if not content_chunk:
            return

        content_chunk, patches = collector.json_render_filter.filter_chunk(content_chunk)
        if patches:
            workflow_events.emit_json_render_update(
                patches=patches,
                member_id=state.member_id,
                team_id=collector.team_id,
            )

        if not content_chunk:
            return

        workflow_events.emit_team_member_content(
            team_id=collector.team_id,
            team_name=collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            content_chunk=content_chunk,
            chunk_index=state.chunk_index,
            member_role=state.role,
            is_final=False,
        )
        state.chunk_index += 1

    def _handle_member_tool_call_started(
        self,
        event: ToolCallStartedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        tool_name, tool_call_id, tool_input, _ = self._extract_tool_details(event)

        workflow_events.emit_team_member_tool_call_started(
            team_id=collector.team_id,
            team_name=collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            tool_name=tool_name,
            member_role=state.role,
            tool_call_id=tool_call_id,
            tool_input=tool_input,
        )

    def _handle_member_tool_call_completed(
        self,
        event: ToolCallCompletedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        tool_name, tool_call_id, tool_input, tool_output = self._extract_tool_details(event)

        workflow_events.emit_team_member_tool_call_completed(
            team_id=collector.team_id,
            team_name=collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            tool_name=tool_name,
            member_role=state.role,
            tool_call_id=tool_call_id,
            tool_input=tool_input,
            tool_output=tool_output or self._ensure_text(getattr(event, "content", None)),
        )

    def _handle_member_run_paused(
        self,
        event: AgentRunPausedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        
        # 1. 像内容事件一样处理 content
        content_chunk = self._ensure_text(getattr(event, "content", ""))
        if content_chunk:
            workflow_events.emit_team_member_content(
                team_id=collector.team_id,
                team_name=collector.team_name,
                member_id=state.member_id,
                member_name=state.name,
                run_id=state.run_id,
                content_chunk=content_chunk,
                chunk_index=state.chunk_index,
                member_role=state.role,
                is_final=False,
            )
            state.chunk_index += 1

        # 2. 如果有工具调用，发射工具调用事件
        # 这对于外部执行工具特别重要，前端可以显示“正在调用本地工具...”
        if hasattr(event, "tools") and event.tools:
            for tool_exec in event.tools:
                workflow_events.emit_team_member_tool_call_started(
                    team_id=collector.team_id,
                    team_name=collector.team_name,
                    member_id=state.member_id,
                    member_name=state.name,
                    run_id=state.run_id,
                    tool_name=getattr(tool_exec, "tool_name", "unknown"),
                    member_role=state.role,
                    tool_call_id=getattr(tool_exec, "tool_call_id", None),
                    tool_input=getattr(tool_exec, "tool_args", {}),
                )

    def _handle_member_run_continued(
        self,
        event: AgentRunContinuedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        content_chunk = self._ensure_text(getattr(event, "content", ""))
        if content_chunk:
            workflow_events.emit_team_member_content(
                team_id=collector.team_id,
                team_name=collector.team_name,
                member_id=state.member_id,
                member_name=state.name,
                run_id=state.run_id,
                content_chunk=content_chunk,
                chunk_index=state.chunk_index,
                member_role=state.role,
                is_final=False,
            )
            state.chunk_index += 1

    def _handle_member_run_failed(
        self,
        event: AgentRunErrorEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        error_message = (
            self._ensure_text(getattr(event, "error", None) or getattr(event, "content", None))
            or "Agent execution failed"
        )

        workflow_events.emit_team_member_failed(
            team_id=collector.team_id,
            team_name=collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            error=error_message,
            member_role=state.role,
        )

    def _handle_member_run_completed(
        self,
        event: AgentRunCompletedEvent,
        collector: StreamCollector,
        built_team: BuiltTeam,
        workflow_events: WorkflowEventEmitter,
    ) -> None:
        state = self._ensure_member_state(event, collector, built_team)
        final_chunk = self._ensure_text(getattr(event, "content", ""))

        execution_time = None
        if getattr(event, "metrics", None) and getattr(event.metrics, "total_elapsed_time", None) is not None:
            execution_time = float(event.metrics.total_elapsed_time)

        response_length = len(final_chunk) if final_chunk else None

        workflow_events.emit_team_member_completed(
            team_id=collector.team_id,
            team_name=collector.team_name,
            member_id=state.member_id,
            member_name=state.name,
            run_id=state.run_id,
            member_role=state.role,
            execution_time=execution_time,
            response_length=response_length,
            content=final_chunk or None,
        )

        collector.member_completions[state.member_id] = event
        if state.role == "result_consolidation":
            collector.final_member_event = event

    def _ensure_member_state(
        self,
        event: Any,
        collector: StreamCollector,
        built_team: BuiltTeam,
        fallback_role: Optional[str] = None,
    ) -> MemberStreamState:
        raw_id = getattr(event, "agent_id", None) or getattr(event, "team_id", None)
        member_id = str(raw_id) if raw_id is not None else collector.team_id

        member_name = getattr(event, "agent_name", None) or getattr(event, "team_name", None)
        if not member_name:
            member_name = built_team.agent_names.get(member_id, collector.team_name)

        member_role = built_team.agent_roles.get(member_id, fallback_role)

        run_id = getattr(event, "run_id", None)
        if run_id is None:
            existing_state = collector.member_states.get(member_id)
            if existing_state is not None:
                run_id = existing_state.run_id
            else:
                run_id = uuid.uuid4().hex

        if member_id == collector.team_id and collector.team_run_id:
            run_id = collector.team_run_id

        state = collector.member_states.get(member_id)
        if state is None:
            state = MemberStreamState(member_id=member_id, name=member_name, role=member_role, run_id=run_id)
            collector.member_states[member_id] = state
        else:
            if member_name:
                state.name = member_name
            if member_role:
                state.role = member_role
            if run_id and state.run_id != run_id:
                state.run_id = run_id
                state.chunk_index = 0

        return state

    def _convert_completed_events(
        self,
        completed: Dict[str, AgentRunCompletedEvent],
        context: CoordinationContext,
    ) -> List[AgentExecutionResult]:
        results: List[AgentExecutionResult] = []
        for event in completed.values():
            run_output = self._event_to_run_output(event)
            results.append(self._run_output_to_execution_result(run_output, context))
        return results

    def _event_to_run_output(self, event: AgentRunCompletedEvent) -> RunOutput:
        return RunOutput(
            run_id=event.run_id,
            agent_id=event.agent_id,
            agent_name=event.agent_name,
            content=event.content,
            model_provider_data=event.model_provider_data,
            references=event.references,
            additional_input=event.additional_input,
            reasoning_steps=event.reasoning_steps,
            reasoning_messages=event.reasoning_messages,
            metrics=event.metrics,
            images=event.images,
            videos=event.videos,
            audio=event.audio,
            response_audio=event.response_audio,
            metadata=event.metadata,
            status=RunStatus.completed,
        )

    def _run_output_to_execution_result(
        self,
        output: RunOutput,
        context: CoordinationContext,
    ) -> AgentExecutionResult:
        agent_name = output.agent_name or "Agent"
        agent_id_value = output.agent_id or agent_name
        try:
            agent_uuid = uuid.UUID(str(agent_id_value))
        except ValueError:
            agent_uuid = uuid.uuid5(uuid.NAMESPACE_URL, str(agent_id_value))

        tools_used = None
        if output.tools:
            tool_names = [tool.tool_name for tool in output.tools if getattr(tool, "tool_name", None)]
            tools_used = tool_names or None

        execution_time = 0.0
        if output.metrics and getattr(output.metrics, "total_elapsed_time", None) is not None:
            execution_time = float(output.metrics.total_elapsed_time)

        success = output.status != RunStatus.error
        error = None if success else "Agent execution failed"

        return AgentExecutionResult(
            agent_id=agent_uuid,
            agent_name=agent_name,
            question=context.message,
            content=output.get_content_as_string() if output.content is not None else "",
            tools_used=tools_used,
            execution_time=execution_time,
            success=success,
            error=error,
        )
