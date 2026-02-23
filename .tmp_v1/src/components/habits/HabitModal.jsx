import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Checkbox } from "@/components/ui/checkbox";

export default function HabitModal({ open, onClose, onSubmit, objectives }) {
  const [formData, setFormData] = useState({
    objective_id: '',
    title: '',
    description: '',
    is_daily: true,
    weekly_frequency: 7,
    specific_days: [0, 1, 2, 3, 4, 5, 6]
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    const dataToSubmit = {
      ...formData,
      weekly_frequency: formData.is_daily ? 7 : formData.specific_days.length
    };
    onSubmit(dataToSubmit);
    setFormData({
      objective_id: '',
      title: '',
      description: '',
      is_daily: true,
      weekly_frequency: 7,
      specific_days: [0, 1, 2, 3, 4, 5, 6]
    });
    onClose();
  };

  const toggleDay = (day) => {
    if (formData.specific_days.includes(day)) {
      setFormData({
        ...formData,
        specific_days: formData.specific_days.filter(d => d !== day)
      });
    } else {
      setFormData({
        ...formData,
        specific_days: [...formData.specific_days, day].sort()
      });
    }
  };

  const days = [
    { value: 1, label: 'Mon' },
    { value: 2, label: 'Tue' },
    { value: 3, label: 'Wed' },
    { value: 4, label: 'Thu' },
    { value: 5, label: 'Fri' },
    { value: 6, label: 'Sat' },
    { value: 0, label: 'Sun' }
  ];

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="bg-zinc-900 border-zinc-800 text-white max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Habit</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-sm text-zinc-400 mb-2 block">Objective</label>
            <Select
              value={formData.objective_id}
              onValueChange={(value) => setFormData({ ...formData, objective_id: value })}
              required
            >
              <SelectTrigger className="bg-zinc-800 border-zinc-700">
                <SelectValue placeholder="Select objective" />
              </SelectTrigger>
              <SelectContent>
                {objectives?.map(obj => (
                  <SelectItem key={obj.id} value={obj.id}>
                    {obj.icon} {obj.title}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div>
            <label className="text-sm text-zinc-400 mb-2 block">Habit Name</label>
            <Input
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="e.g., Morning workout"
              className="bg-zinc-800 border-zinc-700"
              required
            />
          </div>

          <div>
            <label className="text-sm text-zinc-400 mb-2 block">Description (Optional)</label>
            <Textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Add details about this habit"
              className="bg-zinc-800 border-zinc-700"
            />
          </div>

          <div>
            <div className="flex items-center gap-2 mb-3">
              <Checkbox
                checked={formData.is_daily}
                onCheckedChange={(checked) => setFormData({
                  ...formData,
                  is_daily: checked,
                  weekly_frequency: checked ? 7 : formData.weekly_frequency,
                  specific_days: checked ? [0, 1, 2, 3, 4, 5, 6] : formData.specific_days
                })}
              />
              <label className="text-sm text-white">Daily habit</label>
            </div>

            {!formData.is_daily && (
              <div>
                <label className="text-sm text-zinc-400 mb-2 block">Select Days</label>
                <div className="flex gap-2">
                  {days.map(day => (
                    <button
                      key={day.value}
                      type="button"
                      onClick={() => toggleDay(day.value)}
                      className={`w-10 h-10 rounded-lg text-sm font-medium transition-all ${
                        formData.specific_days.includes(day.value)
                          ? 'bg-white text-black'
                          : 'bg-zinc-800 text-zinc-400 hover:bg-zinc-700'
                      }`}
                    >
                      {day.label}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>

          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
            <Button type="submit" className="flex-1 bg-white text-black hover:bg-zinc-200">
              Create
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}