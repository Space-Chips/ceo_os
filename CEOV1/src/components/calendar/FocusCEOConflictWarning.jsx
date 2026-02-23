import React from 'react';
import { AlertTriangle, Calendar as CalendarIcon, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { format } from 'date-fns';

export default function FocusCEOConflictWarning({ conflict, onProceed, onCancel }) {
  if (!conflict?.hasConflict) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/95 backdrop-blur-md">
      <div className="relative w-full max-w-md">
        <div className="absolute inset-0 bg-gradient-to-r from-orange-500/30 to-red-500/30 rounded-[32px] blur-2xl" />
        <div className="relative p-8 rounded-[32px] bg-gradient-to-br from-zinc-900/98 via-zinc-850/98 to-zinc-900/98 backdrop-blur-xl border-2 border-orange-600/50 shadow-[0_24px_96px_rgba(249,115,22,0.5)]">
          
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-orange-500 to-red-600 flex items-center justify-center shadow-lg">
                <AlertTriangle className="w-6 h-6 text-white" />
              </div>
              <div>
                <div className="text-lg font-black text-white">Schedule Conflict</div>
                <div className="text-xs text-orange-400">Events during this session</div>
              </div>
            </div>
          </div>

          <div className="mb-6 space-y-2">
            {conflict.importantConflicts?.length > 0 && (
              <div className="p-4 rounded-xl bg-red-950/40 border border-red-800/60">
                <div className="text-sm font-bold text-red-300 mb-2 flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-red-400 animate-pulse" />
                  Important Events
                </div>
                {conflict.importantConflicts.map(event => (
                  <div key={event.id} className="text-xs text-red-400/80 mb-1 flex items-center gap-2">
                    <CalendarIcon className="w-3 h-3" />
                    {event.event_time} - {event.title}
                  </div>
                ))}
              </div>
            )}

            {conflict.conflicts?.filter(e => !conflict.importantConflicts?.includes(e)).map(event => (
              <div key={event.id} className="p-3 rounded-lg bg-orange-950/30 border border-orange-800/40">
                <div className="text-xs text-orange-300 font-semibold flex items-center gap-2">
                  <CalendarIcon className="w-3 h-3" />
                  {event.event_time} - {event.title}
                </div>
              </div>
            ))}
          </div>

          <div className="text-xs text-zinc-500 mb-6 text-center">
            {conflict.severity === 'high' 
              ? '⚠️ Starting this session will overlap with important events'
              : 'You have scheduled events during this time'}
          </div>

          <div className="flex gap-3">
            <Button
              onClick={onCancel}
              variant="outline"
              className="flex-1 bg-transparent border-zinc-700 text-zinc-400 hover:bg-zinc-800/50"
            >
              Cancel
            </Button>
            <Button
              onClick={onProceed}
              className="flex-1 bg-gradient-to-r from-orange-600 to-red-600 hover:from-orange-700 hover:to-red-700 text-white font-bold"
            >
              Proceed Anyway
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}