import React, { useMemo } from 'react';

import type { Spec } from '@json-render/core';
import { ActionProvider, Renderer, StateProvider, VisibilityProvider } from '@json-render/react';

import { jsonRenderFallback, jsonRenderRegistry } from './registry';

interface JSONRenderSurfaceProps {
  spec: Spec | null;
  onAction?: (actionName: string, context: Record<string, unknown>) => Promise<void> | void;
}

function collectActionNames(spec: Spec | null): string[] {
  if (!spec) return [];

  const names = new Set<string>();
  for (const element of Object.values(spec.elements)) {
    const events = element.on;
    if (!events || typeof events !== 'object') continue;

    for (const binding of Object.values(events)) {
      if (Array.isArray(binding)) {
        for (const item of binding) {
          if (item && typeof item.action === 'string') {
            names.add(item.action);
          }
        }
        continue;
      }

      if (binding && typeof binding.action === 'string') {
        names.add(binding.action);
      }
    }
  }

  return Array.from(names);
}

export const JSONRenderSurface: React.FC<JSONRenderSurfaceProps> = ({ spec, onAction }) => {
  const actionHandlers = useMemo(() => {
    const handlers: Record<string, (params: Record<string, unknown>) => Promise<void>> = {};
    for (const actionName of collectActionNames(spec)) {
      handlers[actionName] = async (params: Record<string, unknown>) => {
        if (!onAction) return;
        await onAction(actionName, params ?? {});
      };
    }
    return handlers;
  }, [spec, onAction]);

  const stateKey = useMemo(() => JSON.stringify(spec?.state ?? {}), [spec?.state]);

  if (!spec) return null;

  return (
    <div className="json-render-surface mt-2 space-y-3">
      <StateProvider key={stateKey} initialState={spec.state ?? {}}>
        <VisibilityProvider>
          <ActionProvider handlers={actionHandlers}>
            <Renderer spec={spec} registry={jsonRenderRegistry} fallback={jsonRenderFallback} />
          </ActionProvider>
        </VisibilityProvider>
      </StateProvider>
    </div>
  );
};
