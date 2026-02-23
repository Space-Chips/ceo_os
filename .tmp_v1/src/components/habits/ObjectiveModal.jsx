import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

export default function ObjectiveModal({ open, onClose, onSubmit }) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    icon: '🎯'
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
    setFormData({ title: '', description: '', icon: '🎯' });
    onClose();
  };

  const icons = ['🎯', '💪', '📚', '💼', '🏃', '🧘', '🎨', '💰', '🏆', '🌱'];

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="bg-zinc-900 border-zinc-800 text-white">
        <DialogHeader>
          <DialogTitle>Create New Objective</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-sm text-zinc-400 mb-2 block">Icon</label>
            <div className="flex gap-2 flex-wrap">
              {icons.map(icon => (
                <button
                  key={icon}
                  type="button"
                  onClick={() => setFormData({ ...formData, icon })}
                  className={`w-10 h-10 rounded-lg flex items-center justify-center text-xl transition-all ${
                    formData.icon === icon
                      ? 'bg-white text-black'
                      : 'bg-zinc-800 hover:bg-zinc-700'
                  }`}
                >
                  {icon}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="text-sm text-zinc-400 mb-2 block">Title</label>
            <Input
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="e.g., Health & Fitness"
              className="bg-zinc-800 border-zinc-700"
              required
            />
          </div>

          <div>
            <label className="text-sm text-zinc-400 mb-2 block">Description (Optional)</label>
            <Textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="What is this objective about?"
              className="bg-zinc-800 border-zinc-700"
            />
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