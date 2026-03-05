import { useMemo } from 'react'
import { type DataPart, useJsonRenderMessage } from '@json-render/react'
import type { ChatMessage } from '../../types/chat'
import MarkdownContent from '../MarkdownContent'
import JSONRenderSurface from '../jsonRender/JSONRenderSurface'
import { Cursor } from './messageStyles'

interface JSONRenderMessageProps {
  message: ChatMessage
  onSendMessage?: (message: string) => void
  onAction?: (actionName: string, context: Record<string, unknown>) => Promise<void> | void
  showCursor?: boolean
}

export default function JSONRenderMessage({ message, onSendMessage, onAction, showCursor = false }: JSONRenderMessageProps) {
  const uiParts = useMemo(() => {
    return Array.isArray(message.uiParts) ? (message.uiParts as DataPart[]) : []
  }, [message.uiParts])

  const { spec, text } = useJsonRenderMessage(uiParts)

  const payloadText = message.payload.type === 1 ? message.payload.content : ''
  const textContent = (message.streamData && message.streamData.trim())
    ? message.streamData
    : (text && text.trim() ? text : payloadText)

  if (!textContent && !spec) return null

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, maxWidth: '100%' }}>
      {textContent ? (
        <div>
          <MarkdownContent content={textContent} onSendMessage={onSendMessage} />
          {showCursor ? <Cursor /> : null}
        </div>
      ) : null}
      {spec ? <JSONRenderSurface spec={spec} onAction={onAction} /> : null}
    </div>
  )
}
