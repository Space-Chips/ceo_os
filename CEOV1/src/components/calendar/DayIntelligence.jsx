import React from 'react';
import { AlertTriangle, Zap, Clock, CheckCircle2 } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function DayIntelligence({ 
  overloadInfo, 
  focusSuggestion, 
  freeTime, 
  habitConflict,
  onStartFocus 
}) {
  if (!overloadInfo && !focusSuggestion && !habitConflict) {
    return null;
  }

  return (
    <div className="space-y-3 mb-6">
      {/* Overload Warning */}
      {overloadInfo?.overloaded && (
        <div className="relative animate-in fade-in slide-in-from-top-2 duration-300">
          <div className="absolute inset-0 bg-zinc-700/15 rounded-xl blur-lg" />
          <div className="relative p-4 rounded-xl bg-zinc-900/70 border border-zinc-700/50 backdrop-blur-sm">
            <div className="flex items-start gap-3">
              <div className="mt-0.5">
                <AlertTriangle className="w-5 h-5 text-zinc-500" />
              </div>
              <div className="flex-1">
                <div className="text-sm font-bold text-zinc-300 mb-1">Overloaded Day</div>
                <div className="text-xs text-zinc-500">
                  {overloadInfo.reason === 'too_many_hours' && `${Math.round(overloadInfo.totalMinutes / 60)}h scheduled - consider reducing load`}
                  {overloadInfo.reason === 'no_breaks' && 'Events back-to-back with no breaks'}
                  {overloadInfo.reason === 'too_many_events' && `${overloadInfo.eventCount} events - might be overwhelming`}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Focus Suggestion */}
      {focusSuggestion?.suggest && (
        <div className="relative animate-in fade-in slide-in-from-top-2 duration-300">
          <div className="absolute inset-0 bg-zinc-700/15 rounded-xl blur-lg" />
          <div className="relative p-4 rounded-xl bg-zinc-900/70 border border-zinc-700/50 backdrop-blur-sm">
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-start gap-3 flex-1">
                <div className="mt-0.5">
                  <Zap className="w-5 h-5 text-zinc-500" />
                </div>
                <div className="flex-1">
                  <div className="text-sm font-bold text-zinc-300 mb-1">Focus Opportunity</div>
                  <div className="text-xs text-zinc-500">
                    {focusSuggestion.reason === 'no_events' && 'Day is free - perfect for deep work'}
                    {focusSuggestion.reason === 'light_schedule' && 'Light schedule - ideal for a focus session'}
                  </div>
                </div>
              </div>
              <Button
                onClick={onStartFocus}
                size="sm"
                className="bg-zinc-800 hover:bg-zinc-700 text-white h-9 px-4 text-xs font-bold rounded-lg border border-zinc-700/50"
              >
                Start {focusSuggestion.recommendedDuration}min
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Habit-Calendar Conflict */}
      {habitConflict?.conflict && (
        <div className="relative animate-in fade-in slide-in-from-top-2 duration-300">
          <div className="absolute inset-0 bg-zinc-700/15 rounded-xl blur-lg" />
          <div className="relative p-4 rounded-xl bg-zinc-900/70 border border-zinc-700/50 backdrop-blur-sm">
            <div className="flex items-start gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-5 h-5 text-zinc-500" />
              </div>
              <div className="flex-1">
                <div className="text-sm font-bold text-zinc-300 mb-1">Habit Conflict</div>
                <div className="text-xs text-zinc-500">
                  {habitConflict.habitCount} habit{habitConflict.habitCount > 1 ? 's' : ''} scheduled + {Math.round(habitConflict.eventMinutes / 60)}h of events - might be challenging
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Free Time Display */}
      {freeTime && (
        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-r from-zinc-600/15 to-zinc-500/15 rounded-xl blur-lg" />
          <div className="relative p-4 rounded-xl bg-zinc-900/60 border border-zinc-700/50 backdrop-blur-sm">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Clock className="w-5 h-5 text-zinc-500" />
                <div>
                  <div className="text-sm font-bold text-zinc-300">Real Free Time</div>
                  <div className="text-xs text-zinc-600">After events & sleep</div>
                </div>
              </div>
              <div className="text-right">
                <div className="text-2xl font-black bg-gradient-to-r from-white to-zinc-400 bg-clip-text text-transparent tabular-nums">
                  {freeTime.freeTimeHours}h{freeTime.freeTimeRemainingMinutes > 0 ? `${freeTime.freeTimeRemainingMinutes}m` : ''}
                </div>
                <div className="text-[9px] text-zinc-600 font-bold uppercase tracking-wider">Available</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}