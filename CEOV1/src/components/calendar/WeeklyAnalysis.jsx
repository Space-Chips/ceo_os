import React from 'react';
import { TrendingUp, Clock, Target, Calendar as CalendarIcon } from 'lucide-react';

export default function WeeklyAnalysis({ analysis }) {
  if (!analysis) return null;

  return (
    <div className="relative mb-6">
      {/* Texture background */}
      <div className="absolute inset-0 opacity-[0.02] pointer-events-none rounded-2xl overflow-hidden">
        <div className="absolute inset-0" style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
        }} />
      </div>
      
      <div className="absolute inset-0 bg-gradient-to-r from-indigo-700/10 to-purple-700/10 rounded-2xl blur-xl" />
      <div className="relative p-6 rounded-2xl bg-gradient-to-br from-zinc-900/90 to-zinc-950/90 backdrop-blur-sm border border-indigo-900/20 shadow-[0_16px_64px_rgba(0,0,0,0.6)]">
        <div className="flex items-center gap-3 mb-5">
          <TrendingUp className="w-5 h-5 text-indigo-400" />
          <h3 className="text-base font-black text-indigo-300 tracking-tight">Week Overview</h3>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div className="text-center p-4 rounded-xl bg-gradient-to-br from-blue-950/40 to-cyan-950/40 border border-blue-800/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.03)]">
            <CalendarIcon className="w-5 h-5 mx-auto mb-2 text-blue-400" />
            <div className="text-2xl font-black text-blue-300 mb-1 tabular-nums">{analysis.totalEventHours}h</div>
            <div className="text-[9px] text-blue-500/60 uppercase tracking-wider font-bold">Scheduled</div>
          </div>

          <div className="text-center p-4 rounded-xl bg-gradient-to-br from-amber-950/40 to-yellow-950/40 border border-amber-800/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.03)]">
            <Target className="w-5 h-5 mx-auto mb-2 text-amber-400" />
            <div className="text-2xl font-black text-amber-300 mb-1 tabular-nums">{analysis.importantEventHours}h</div>
            <div className="text-[9px] text-amber-500/60 uppercase tracking-wider font-bold">Important</div>
          </div>

          <div className="text-center p-4 rounded-xl bg-gradient-to-br from-emerald-950/40 to-green-950/40 border border-emerald-800/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.03)]">
            <Clock className="w-5 h-5 mx-auto mb-2 text-emerald-400" />
            <div className="text-2xl font-black text-emerald-300 mb-1 tabular-nums">{analysis.freeTimeHours}h</div>
            <div className="text-[9px] text-emerald-500/60 uppercase tracking-wider font-bold">Free Time</div>
          </div>

          <div className="text-center p-4 rounded-xl bg-gradient-to-br from-purple-950/40 to-pink-950/40 border border-purple-800/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.03)]">
            <TrendingUp className="w-5 h-5 mx-auto mb-2 text-purple-400" />
            <div className="text-2xl font-black text-purple-300 mb-1 tabular-nums">{analysis.percentageImportant}%</div>
            <div className="text-[9px] text-purple-500/60 uppercase tracking-wider font-bold">Priority</div>
          </div>
        </div>

        <div className="mt-4 text-xs text-indigo-400/60 text-center font-medium">
          {analysis.percentageFree}% of waking hours remain free
        </div>
      </div>
    </div>
  );
}