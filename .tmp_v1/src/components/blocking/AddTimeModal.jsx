import React, { useState } from 'react';
import { useLanguage } from '../LanguageProvider';
import { X, Clock } from 'lucide-react';
import { Button } from '@/components/ui/button';
import CooldownScreen from './CooldownScreen';

export default function AddTimeModal({ 
  entityName, 
  entityType = 'app',
  onAddTime, 
  onClose 
}) {
  const { t } = useLanguage();
  const [selectedMinutes, setSelectedMinutes] = useState(10);
  const [showCooldown, setShowCooldown] = useState(false);

  const timeOptions = [10];

  const handleConfirm = () => {
    setShowCooldown(true);
  };

  const handleCooldownComplete = () => {
    if (onAddTime) onAddTime(selectedMinutes);
    setShowCooldown(false);
    if (onClose) onClose();
  };

  const handleCooldownCancel = () => {
    setShowCooldown(false);
  };

  if (showCooldown) {
    return (
      <CooldownScreen 
        onComplete={handleCooldownComplete}
        onCancel={handleCooldownCancel}
        message="Are you sure?"
      />
    );
  }

  return (
    <div className="fixed inset-0 bg-black/90 backdrop-blur-xl z-[100] flex items-center justify-center p-6">
      <div className="relative max-w-md w-full">
        <div className="absolute inset-0 bg-gradient-to-r from-blue-500/10 to-purple-500/10 rounded-[28px] blur-2xl" />
        <div className="relative p-8 rounded-[28px] bg-gradient-to-br from-zinc-900/95 to-zinc-950/95 border border-zinc-800/60 shadow-[0_24px_96px_rgba(0,0,0,0.7)]">
          <button
            onClick={onClose}
            className="absolute top-6 right-6 p-2 hover:bg-zinc-800/50 rounded-lg transition-all active:scale-95"
          >
            <X className="w-4 h-4 text-zinc-500" />
          </button>

          <div className="text-center mb-8">
            <div className="w-14 h-14 mx-auto mb-4 rounded-2xl bg-zinc-800/60 border border-zinc-700/50 flex items-center justify-center shadow-[inset_0_2px_8px_rgba(0,0,0,0.4)]">
              <Clock className="w-7 h-7 text-zinc-400" />
            </div>
            <h2 className="text-xl font-black text-white mb-2 tracking-tight">
              Add Screen Time
            </h2>
            <p className="text-sm text-zinc-500">
              for <span className="text-white font-semibold">{entityName}</span>
            </p>
          </div>

          <div className="mb-8">
            <div className="text-xs text-zinc-600 font-bold uppercase tracking-wider mb-4 text-center">
              Fixed Duration
            </div>
            <div className="flex justify-center">
              <div className="p-6 rounded-xl bg-white text-black font-black text-2xl shadow-[0_8px_24px_rgba(255,255,255,0.2)]">
                10 minutes
              </div>
            </div>
          </div>

          <div className="relative mb-6">
            <div className="absolute inset-0 bg-yellow-500/10 rounded-xl blur-lg" />
            <div className="relative px-4 py-3 rounded-xl bg-yellow-950/30 border border-yellow-900/40">
              <p className="text-xs text-yellow-300/80 font-medium leading-relaxed">
                Adding time interrupts your focus flow. Consider if this is truly necessary.
              </p>
            </div>
          </div>

          <Button
            onClick={handleConfirm}
            className="w-full bg-white text-black hover:bg-zinc-200 h-12 font-bold rounded-xl active:scale-[0.98] transition-all duration-150"
          >
            Add {selectedMinutes} minutes
          </Button>
        </div>
      </div>
    </div>
  );
}