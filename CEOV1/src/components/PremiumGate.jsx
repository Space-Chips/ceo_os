import React from 'react';
import { usePremium } from './PremiumProvider';
import { Button } from '@/components/ui/button';
import { Crown, Sparkles } from 'lucide-react';
import { base44 } from '@/api/base44Client';

export default function PremiumGate({ 
  feature, 
  limit, 
  current, 
  children,
  compact = false
}) {
  const { isPremiumUser } = usePremium();

  // Si premium ou sous la limite, afficher le contenu
  if (isPremiumUser || current < limit) {
    return children;
  }

  // Limite atteinte - afficher le message premium
  const messages = {
    focus_daily: {
      title: 'Focus Mode Limit',
      description: `You've used your daily Focus session (${limit}/day). Upgrade to unlock unlimited sessions.`,
      icon: '🎯'
    },
    focus_duration: {
      title: 'Extended Focus',
      description: `Free users can focus up to ${limit} minutes. Upgrade for unlimited duration.`,
      icon: '⏱️'
    },
    ceo_weekly: {
      title: 'CEO Mode Limit',
      description: `You've used your weekly CEO session (${limit}/week). Upgrade for unlimited sessions.`,
      icon: '👔'
    },
    ceo_duration: {
      title: 'Extended CEO Mode',
      description: `Free users can use CEO Mode up to ${limit} minutes. Upgrade for unlimited duration.`,
      icon: '⏱️'
    },
    habits: {
      title: 'More Habits',
      description: `Free users can track up to ${limit} habits. Upgrade to track unlimited habits.`,
      icon: '✅'
    },
    tasks: {
      title: 'More Tasks',
      description: `Free users can have up to ${limit} active tasks. Upgrade for unlimited tasks.`,
      icon: '📋'
    },
    reports: {
      title: 'Premium Reports',
      description: 'Advanced productivity reports are available for Premium users only.',
      icon: '📊'
    },
    calendar_advanced: {
      title: 'Advanced Calendar',
      description: 'Birthday tracking and advanced calendar features are Premium-only.',
      icon: '📅'
    }
  };

  const message = messages[feature] || messages.habits;

  if (compact) {
    return (
      <div className="relative">
        <div className="absolute inset-0 bg-gradient-to-r from-amber-500/20 to-orange-500/20 rounded-xl blur-xl" />
        <div className="relative p-4 rounded-xl bg-zinc-900/80 border border-amber-500/30">
          <div className="flex items-center gap-3">
            <div className="text-2xl">{message.icon}</div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-bold text-amber-300 mb-0.5">{message.title}</div>
              <div className="text-xs text-zinc-400">{message.description}</div>
            </div>
            <Button
              onClick={() => base44.stripe?.redirectToCheckout?.()}
              size="sm"
              className="bg-gradient-to-r from-amber-500 to-orange-500 text-white hover:from-amber-600 hover:to-orange-600 h-8 px-4 text-xs font-bold flex-shrink-0"
            >
              <Crown className="w-3 h-3 mr-1" />
              Unlock
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="relative">
      <div className="absolute inset-0 bg-gradient-to-r from-amber-500/20 to-orange-500/20 rounded-2xl blur-2xl" />
      <div className="relative p-8 rounded-2xl bg-zinc-900/90 border border-amber-500/40 text-center">
        <div className="text-5xl mb-4">{message.icon}</div>
        <h3 className="text-xl font-black text-white mb-2 tracking-tight">{message.title}</h3>
        <p className="text-sm text-zinc-400 mb-6">{message.description}</p>
        <Button
          onClick={() => base44.stripe?.redirectToCheckout?.()}
          className="bg-gradient-to-r from-amber-500 to-orange-500 text-white hover:from-amber-600 hover:to-orange-600 h-12 px-8 font-bold rounded-xl"
        >
          <Crown className="w-4 h-4 mr-2" />
          Unlock Premium
        </Button>
      </div>
    </div>
  );
}