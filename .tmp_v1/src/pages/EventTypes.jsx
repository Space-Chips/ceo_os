import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, Plus, Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useLanguage } from '../components/LanguageProvider';

const colorOptions = [
  { value: 'blue', label: 'Blue', bg: 'bg-blue-200', border: 'border-blue-300' },
  { value: 'green', label: 'Green', bg: 'bg-green-200', border: 'border-green-300' },
  { value: 'purple', label: 'Purple', bg: 'bg-purple-200', border: 'border-purple-300' },
  { value: 'pink', label: 'Pink', bg: 'bg-pink-200', border: 'border-pink-300' },
  { value: 'orange', label: 'Orange', bg: 'bg-orange-200', border: 'border-orange-300' },
  { value: 'red', label: 'Red', bg: 'bg-red-200', border: 'border-red-300' },
  { value: 'yellow', label: 'Yellow', bg: 'bg-yellow-200', border: 'border-yellow-300' },
  { value: 'teal', label: 'Teal', bg: 'bg-teal-200', border: 'border-teal-300' }
];

export default function EventTypes() {
  const { t } = useLanguage();
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ name: '', color: 'blue' });

  const { data: eventTypes = [] } = useQuery({
    queryKey: ['eventTypes'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.EventType.filter({ created_by: user.email });
    }
  });

  const createMutation = useMutation({
    mutationFn: async (data) => {
      const user = await base44.auth.me();
      return await base44.entities.EventType.create({
        ...data,
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['eventTypes']);
      setFormData({ name: '', color: 'blue' });
      setShowForm(false);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => base44.entities.EventType.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries(['eventTypes']);
    }
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (formData.name.trim()) {
      createMutation.mutate(formData);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 relative overflow-hidden">
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-2xl mx-auto relative">
        <div className="flex items-center justify-between mb-6">
          <Link to={createPageUrl('Calendar')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">{t('back')}</span>
          </Link>
          
          <h1 className="text-2xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            Event Types
          </h1>
          
          <div className="w-20" />
        </div>

        {/* Add Type Button */}
        <div className="mb-6">
          <button
            onClick={() => setShowForm(!showForm)}
            className="w-full py-4 rounded-2xl bg-white text-black border-2 border-zinc-200 hover:bg-zinc-100 active:scale-[0.98] transition-all duration-150 shadow-[0_8px_24px_rgba(255,255,255,0.15)] font-bold flex items-center justify-center gap-2"
          >
            <Plus className="w-5 h-5" />
            Add Event Type
          </button>
        </div>

        {/* Add Form */}
        {showForm && (
          <div className="mb-6 relative">
            <div className="absolute inset-0 bg-gradient-to-r from-indigo-500/15 to-purple-500/15 rounded-2xl blur-xl" />
            <form onSubmit={handleSubmit} className="relative p-6 rounded-2xl bg-zinc-900/80 border border-zinc-800/50 shadow-[0_12px_48px_rgba(0,0,0,0.6)]">
              <div className="space-y-4">
                <div>
                  <label className="text-sm text-zinc-400 mb-2 block font-medium">Type Name</label>
                  <Input
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g., Work, Sport, Personal"
                    className="bg-zinc-800 border-zinc-700 text-white"
                    required
                  />
                </div>

                <div>
                  <label className="text-sm text-zinc-400 mb-3 block font-medium">Color</label>
                  <div className="grid grid-cols-4 gap-2">
                    {colorOptions.map(color => (
                      <button
                        key={color.value}
                        type="button"
                        onClick={() => setFormData({ ...formData, color: color.value })}
                        className={`p-3 rounded-xl border-2 transition-all duration-150 ${
                          formData.color === color.value
                            ? `${color.border} ${color.bg} shadow-lg scale-105`
                            : 'border-zinc-800 bg-zinc-900/50 hover:border-zinc-700'
                        }`}
                      >
                        <div className={`w-full h-8 rounded-lg ${color.bg} ${formData.color !== color.value && 'opacity-50'}`} />
                      </button>
                    ))}
                  </div>
                </div>

                <div className="flex gap-3 pt-2">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setShowForm(false)}
                    className="flex-1"
                  >
                    {t('cancel')}
                  </Button>
                  <Button
                    type="submit"
                    className="flex-1 bg-white text-black hover:bg-zinc-200"
                    disabled={createMutation.isPending}
                  >
                    {createMutation.isPending ? 'Creating...' : t('add')}
                  </Button>
                </div>
              </div>
            </form>
          </div>
        )}

        {/* Event Types List */}
        <div className="space-y-3">
          {eventTypes.map(type => {
            const colorConfig = colorOptions.find(c => c.value === type.color) || colorOptions[0];
            return (
              <div key={type.id} className="relative group">
                <div className="absolute inset-0 bg-gradient-to-r from-zinc-700/10 to-zinc-600/10 rounded-2xl blur-lg opacity-50" />
                <div className="relative p-5 rounded-2xl bg-zinc-900/70 border border-zinc-800/50 hover:border-zinc-700/60 transition-all duration-150 shadow-[0_8px_24px_rgba(0,0,0,0.5)]">
                  <div className="flex items-center gap-4">
                    <div className={`w-12 h-12 rounded-xl ${colorConfig.bg} shadow-lg`} />
                    <div className="flex-1">
                      <div className="font-bold text-white text-base">{type.name}</div>
                      <div className="text-xs text-zinc-500 capitalize">{type.color}</div>
                    </div>
                    <button
                      onClick={() => {
                        if (window.confirm('Delete this event type?')) {
                          deleteMutation.mutate(type.id);
                        }
                      }}
                      className="opacity-0 group-hover:opacity-100 transition-opacity p-2 hover:bg-zinc-800/50 rounded-lg active:scale-95"
                    >
                      <Trash2 className="w-4 h-4 text-red-500" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}

          {eventTypes.length === 0 && !showForm && (
            <div className="text-center py-16">
              <div className="text-zinc-700 text-6xl mb-4">🎨</div>
              <div className="text-zinc-600 text-sm font-medium mb-4">No event types yet</div>
              <div className="text-zinc-700 text-xs">Click the button above to add your first type</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}