"""json-render schema manager for TGO AI."""

from __future__ import annotations

import json
from pathlib import Path
from typing import List, Optional

from app.core.logging import get_logger

logger = get_logger(__name__)

_MODULE_DIR = Path(__file__).resolve().parent
_SCHEMA_PATH = _MODULE_DIR / "schema" / "spec_stream_line.json"
_EXAMPLES_DIR = _MODULE_DIR / "examples"

JSON_RENDER_SPEC_FENCE_OPEN = "```spec"
JSON_RENDER_SPEC_FENCE_CLOSE = "```"


class JsonRenderSchemaManager:
    """Manages json-render schema loading and system prompt generation."""

    def __init__(
        self,
        *,
        schema_path: Optional[Path] = None,
        examples_dir: Optional[Path] = None,
    ) -> None:
        self._schema_path = schema_path or _SCHEMA_PATH
        self._examples_dir = examples_dir or _EXAMPLES_DIR
        self._schema: Optional[dict] = None
        self._examples: Optional[str] = None
        self._load()

    def _load(self) -> None:
        if self._schema_path.exists():
            self._schema = json.loads(self._schema_path.read_text(encoding="utf-8"))
            logger.info("json-render patch schema loaded", path=str(self._schema_path))
        else:
            logger.warning("json-render patch schema not found", path=str(self._schema_path))

        if self._examples_dir.exists():
            parts: List[str] = []
            for p in sorted(self._examples_dir.glob("*.jsonl")):
                name = p.stem
                content = p.read_text(encoding="utf-8").strip()
                parts.append(f"### {name}\n```text\n{content}\n```")
            self._examples = "\n\n".join(parts) if parts else None
            logger.info("json-render examples loaded", count=len(parts))

    @property
    def schema_json(self) -> Optional[str]:
        if self._schema is None:
            return None
        return json.dumps(self._schema, indent=2, ensure_ascii=False)

    def generate_system_prompt(
        self,
        *,
        role_description: str = "",
        workflow_description: str = "",
        ui_description: str = "",
        include_schema: bool = True,
        include_examples: bool = True,
    ) -> str:
        """Assemble the json-render instruction block for the LLM prompt."""
        parts: List[str] = []
        parts.append(_JSON_RENDER_PROTOCOL_INSTRUCTIONS)

        if role_description:
            parts.append(f"## Role\n{role_description}")

        if workflow_description:
            parts.append(f"## Workflow\n{workflow_description}")

        if ui_description:
            parts.append(f"## UI Guidelines\n{ui_description}")

        if include_schema and self._schema is not None:
            parts.append(
                "## json-render Patch Schema\n"
                "Each JSONL patch line MUST validate against this schema.\n"
                f"```json\n{self.schema_json}\n```"
            )

        if include_examples and self._examples:
            parts.append(f"## json-render Examples\n{self._examples}")

        return "\n\n".join(parts)


_JSON_RENDER_PROTOCOL_INSTRUCTIONS = f"""\
## json-render Response Protocol

When generating rich UI you MUST follow these rules:

1. First write conversational text.
2. Then output JSONL SpecStream patch lines inside a fenced block:
   - opening fence: `{JSON_RENDER_SPEC_FENCE_OPEN}`
   - closing fence: `{JSON_RENDER_SPEC_FENCE_CLOSE}`
3. Inside the fence, each line MUST be a single RFC 6902 patch object.
4. Patches MUST build a json-render spec object with this shape:
   - `root`: string
   - `elements`: object map of element definitions
   - optional `state`: object
5. Each element MUST contain:
   - `type`: component name
   - `props`: object
   - optional `children`: string[]
   - optional `on`: event-action bindings
6. Use RFC 6902 operations: `add`, `replace`, `remove`, `move`, `copy`, `test`.
7. For interactive controls (button/form), bind events through `on` with action names and params.
8. Prefer structured components over plain text dumps:
   - key/value rows: `KV` or `PriceRow`
   - grouped blocks: `Section`
   - status and tags: `Badge`
   - action area: `ButtonGroup`
9. For order/invoice scenarios, strongly prefer this composition:
   - root `Card` with `variant: "order"`
   - header row with order id + status `Badge`
   - `Section` blocks for shipping, items, and payment
   - each line item uses `OrderItem`
   - totals use `PriceRow`; payable/total amount should set `emphasis=true`
   - action buttons are grouped in `ButtonGroup`
10. Available component types include:
   `Card`, `Column`, `Row`, `Text`, `Divider`, `Image`, `Button`, `ButtonGroup`,
   `Section`, `KV`, `PriceRow`, `Badge`, `OrderItem`,
   `Input`/`TextField`, `Checkbox`/`CheckBox`, `DateTimeInput`, `MultipleChoice`.
11. If you cannot produce valid SpecStream patches, return plain text only and DO NOT emit a spec fence.
"""
