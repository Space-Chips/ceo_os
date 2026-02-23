import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from '@/components/ui/button';
import { Zap } from 'lucide-react';

export default function FocusModeQuickStart({ open, onClose, onStart }) {
  const [duration, setDuration] = useState(() => {
    const lastDuration = localStorage.getItem('lastFocusDuration');
    return lastDuration ? parseInt(lastDuration) : 25;
  });

  const durations = [15, 25, 45, 60, 90, 120];

  const handleStart = () => {
    localStorage.setItem('lastFocusDuration', duration.toString());
    onStart(duration);
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="bg-zinc-900 border-zinc-800 text-white">
        <DialogHeader>
          <DialogTitle>Quick Focus Session</DialogTitle>
        </DialogHeader>
        <div className="space-y-6">
          <div>
            <label className="text-sm text-zinc-400 mb-3 block">Select Duration</label>
            <div className="grid grid-cols-3 gap-3">
              {durations.map(d => (
                <button
                  key={d}
                  onClick={() => setDuration(d)}
                  className={`p-4 rounded-xl text-center transition-all ${
                    duration === d
                      ? 'bg-white text-black font-bold'
                      : 'bg-zinc-800 text-zinc-400 hover:bg-zinc-700'
                  }`}
                >
                  <div className="text-lg font-bold">{d}</div>
                  <div className="text-xs">min</div>
                </button>
              ))}
            </div>
          </div>

          <Button
            onClick={handleStart}
            className="w-full bg-white text-black hover:bg-zinc-200"
          >
            <Zap className="w-4 h-4 mr-2" />
            Start Focus Mode
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}