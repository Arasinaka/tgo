import React, { useCallback, useMemo } from 'react';
import { type DataPart, useJsonRenderMessage } from '@json-render/react';

import type { Message } from '@/types';
import MarkdownContent from '../MarkdownContent';
import { chatMessagesApiService } from '@/services/chatMessagesApi';
import { JSONRenderSurface } from '../jsonRender/JSONRenderSurface';

interface JSONRenderMessageProps {
  message: Message;
  isStaff: boolean;
  onSendMessage?: (message: string) => void;
}

const JSONRenderMessage: React.FC<JSONRenderMessageProps> = ({ message, isStaff, onSendMessage }) => {
  const meta = message.metadata ?? {};
  const uiParts = useMemo(() => {
    return Array.isArray(meta.ui_parts) ? (meta.ui_parts as DataPart[]) : [];
  }, [meta.ui_parts]);
  const { spec, text } = useJsonRenderMessage(uiParts);
  const textContent = text && text.trim() ? text : message.content;

  const handleAction = useCallback(
    async (actionName: string, context: Record<string, unknown>) => {
      if (!message.channelId || message.channelType == null) {
        console.warn('UI action: missing channel info, cannot send');
        return;
      }
      try {
        await chatMessagesApiService.sendUIAction({
          channel_id: message.channelId,
          channel_type: message.channelType,
          action_name: actionName,
          context,
        });
      } catch (err) {
        console.error('Failed to send UI user action:', err);
      }
    },
    [message.channelId, message.channelType]
  );

  return (
    <div
      className={`json-render-message inline-block max-w-full p-3 shadow-sm overflow-hidden ${
        isStaff
          ? 'bg-blue-500 dark:bg-blue-600 text-white rounded-lg rounded-tr-none'
          : 'bg-white dark:bg-gray-700 rounded-lg rounded-tl-none border border-gray-100 dark:border-gray-600'
      }`}
    >
      {textContent && textContent.trim() && (
        <div className={`text-sm ${isStaff ? 'text-white' : 'text-gray-900 dark:text-gray-100'}`}>
          <MarkdownContent
            content={textContent}
            className={isStaff ? 'markdown-white' : ''}
            onSendMessage={onSendMessage}
          />
        </div>
      )}
      {spec && <JSONRenderSurface spec={spec} onAction={handleAction} />}
    </div>
  );
};

export default JSONRenderMessage;
