import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Clock, AlertCircle, Calendar as CalendarIcon, Repeat } from 'lucide-react';
import { format, addHours, addMinutes, addDays, setHours, setMinutes, isBefore, startOfDay } from 'date-fns';

export default function RestPeriodModal({ open, onClose, onSchedule, isInFocusMode }) {
  const [duration, setDuration] = useState(30);
  const [reason, setReason] = useState('');
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedHour, setSelectedHour] = useState('14');
  const [selectedMinute, setSelectedMinute] = useState('00');
  const [isRecurring, setIsRecurring] = useState(false);
  const [error, setError] = useState('');

  const handleSchedule = () => {
    if (!reason.trim()) {
      setError('Please provide a reason for your break');
      return;
    }

    if (isInFocusMode) {
      setError('Cannot schedule breaks while in Focus Mode');
      return;
    }

    // Construct the scheduled time from selected date + time
    const scheduledDateTime = setMinutes(
      setHours(startOfDay(selectedDate), parseInt(selectedHour)),
      parseInt(selectedMinute)
    );

    // Validate: must be at least 2 hours from now
    const now = new Date();
    const minimumTime = addHours(now, 2);

    if (isBefore(scheduledDateTime, minimumTime)) {
      setError('Break must be scheduled at least 2 hours in advance');
      return;
    }

    onSchedule({
      scheduled_start_time: scheduledDateTime.toISOString(),
      duration_minutes: duration,
      reason: reason.trim(),
      is_recurring: isRecurring
    });

    setReason('');
    setDuration(30);
    setSelectedDate(new Date());
    setSelectedHour('14');
    setSelectedMinute('00');
    setIsRecurring(false);
    setError('');
  };

  const now = new Date();
  const minimumTime = addHours(now, 2);

  // Generate hour options (0-23)
  const hours = Array.from({ length: 24 }, (_, i) => i.toString().padStart(2, '0'));
  // Generate minute options (00, 15, 30, 45)
  const minutes = ['00', '15', '30', '45'];

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="bg-zinc-900 border-zinc-800 text-white max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-xl font-black">
            <Clock className="w-5 h-5 text-blue-400" />
            Schedule Rest Period
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4 pt-2">
          {isInFocusMode && (
            <div className="p-3 rounded-lg bg-red-950/30 border border-red-900/40 flex items-start gap-2">
              <AlertCircle className="w-4 h-4 text-red-400 flex-shrink-0 mt-0.5" />
              <div className="text-xs text-red-300">
                You cannot schedule breaks while in Focus Mode. Exit Focus Mode first.
              </div>
            </div>
          )}

          <div>
            <label className="text-xs text-zinc-500 font-bold uppercase tracking-wider mb-2 block">
              Break Duration
            </label>
            <Select value={duration.toString()} onValueChange={(v) => setDuration(parseInt(v))}>
              <SelectTrigger className="bg-zinc-800 border-zinc-700">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="15">15 minutes</SelectItem>
                <SelectItem value="30">30 minutes</SelectItem>
                <SelectItem value="45">45 minutes</SelectItem>
                <SelectItem value="60">1 hour</SelectItem>
                <SelectItem value="90">1.5 hours</SelectItem>
                <SelectItem value="120">2 hours</SelectItem>
                <SelectItem value="180">3 hours</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <label className="text-xs text-zinc-500 font-bold uppercase tracking-wider mb-2 block">
              Reason for Break
            </label>
            <Textarea
              value={reason}
              onChange={(e) => {
                setReason(e.target.value);
                setError('');
              }}
              placeholder="E.g., Lunch break, Family time, Important call..."
              className="bg-zinc-800 border-zinc-700 h-24 resize-none"
            />
          </div>

          <div>
            <label className="text-xs text-zinc-500 font-bold uppercase tracking-wider mb-2 block">
              Schedule Date & Time
            </label>
            <div className="space-y-3">
              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className="w-full justify-start bg-zinc-800 border-zinc-700 hover:bg-zinc-750">
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {format(selectedDate, 'PPP')}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0 bg-zinc-900 border-zinc-800">
                  <Calendar
                    mode="single"
                    selected={selectedDate}
                    onSelect={(date) => {
                      if (date) {
                        setSelectedDate(date);
                        setError('');
                      }
                    }}
                    disabled={(date) => isBefore(date, startOfDay(new Date()))}
                  />
                </PopoverContent>
              </Popover>

              <div className="grid grid-cols-2 gap-2">
                <Select value={selectedHour} onValueChange={(v) => { setSelectedHour(v); setError(''); }}>
                  <SelectTrigger className="bg-zinc-800 border-zinc-700">
                    <SelectValue placeholder="Hour" />
                  </SelectTrigger>
                  <SelectContent>
                    {hours.map(h => (
                      <SelectItem key={h} value={h}>{h}:00</SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                <Select value={selectedMinute} onValueChange={(v) => { setSelectedMinute(v); setError(''); }}>
                  <SelectTrigger className="bg-zinc-800 border-zinc-700">
                    <SelectValue placeholder="Min" />
                  </SelectTrigger>
                  <SelectContent>
                    {minutes.map(m => (
                      <SelectItem key={m} value={m}>:{m}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>

          <button
            onClick={() => setIsRecurring(!isRecurring)}
            className={`w-full p-3 rounded-lg border transition-all duration-150 flex items-center gap-2 ${
              isRecurring 
                ? 'bg-blue-950/30 border-blue-800/50' 
                : 'bg-zinc-850/40 border-zinc-800/40 hover:border-zinc-700/50'
            }`}
          >
            <div className={`w-5 h-5 rounded border-2 flex items-center justify-center transition-all ${
              isRecurring ? 'border-blue-500 bg-blue-500' : 'border-zinc-700'
            }`}>
              {isRecurring && <div className="w-2 h-2 rounded-sm bg-white" />}
            </div>
            <Repeat className="w-4 h-4 text-zinc-400" />
            <span className="text-sm font-medium text-zinc-300">Repeat weekly</span>
          </button>

          <div className="p-3 rounded-lg bg-zinc-850/60 border border-zinc-800/60">
            <div className="text-xs text-zinc-500 mb-1">Break will start at:</div>
            <div className="text-sm font-bold text-blue-400">
              {format(
                setMinutes(setHours(startOfDay(selectedDate), parseInt(selectedHour)), parseInt(selectedMinute)),
                'PPP, h:mm a'
              )}
            </div>
            <div className="text-xs text-zinc-600 mt-1">
              Restrictions paused for {duration} minutes
            </div>
            {isRecurring && (
              <div className="text-xs text-blue-400 mt-1 flex items-center gap-1">
                <Repeat className="w-3 h-3" />
                Repeats every week
              </div>
            )}
          </div>

          {error && (
            <div className="p-3 rounded-lg bg-red-950/30 border border-red-900/40 text-xs text-red-300">
              {error}
            </div>
          )}

          <div className="flex gap-2 pt-2">
            <Button
              onClick={onClose}
              variant="outline"
              className="flex-1 border-zinc-700 hover:bg-zinc-800"
            >
              Cancel
            </Button>
            <Button
              onClick={handleSchedule}
              disabled={isInFocusMode}
              className="flex-1 bg-white text-black hover:bg-zinc-200 font-bold"
            >
              Schedule Break
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}