import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { ArrowLeft } from 'lucide-react';
import { useLanguage } from '../components/LanguageProvider';

export default function SettingsPermissions() {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 pb-12 relative overflow-hidden">
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-3xl mx-auto relative">
        <div className="flex items-center justify-between mb-6">
          <Link to={createPageUrl('Settings')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">{t('back')}</span>
          </Link>
          
          <h1 className="text-xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('permissions')}
          </h1>
          
          <div className="w-20" />
        </div>

        <div className="space-y-6">
          <div className="relative">
            <div className="relative p-5 rounded-xl bg-zinc-900/60 border border-zinc-800/50 shadow-[0_8px_32px_rgba(0,0,0,0.4)]">
              <p className="text-zinc-400 text-sm leading-relaxed">
                This application may request certain permissions from your device to provide its full functionality. Below is an explanation of what permissions we request and why.
              </p>
            </div>
          </div>

          <div className="space-y-5">
            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>
                  Notifications
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  We request notification permission to send you reminders about your habits, upcoming calendar events, and focus session completions. These notifications help you stay on track with your productivity goals. You can disable notifications at any time in your device settings.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-purple-500"></span>
                  Calendar Access <span className="text-[10px] text-zinc-600 font-normal">(Optional)</span>
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  If you choose to sync with your device calendar, we request calendar read and write permissions. This allows the app to display your events and create new calendar entries. This permission is entirely optional and the app functions without it.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                  Storage
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  The app needs storage permission to save your data locally on your device. This ensures your productivity data is accessible even when offline and improves app performance.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                  Screen Time Tracking <span className="text-[10px] text-zinc-600 font-normal">(Mobile)</span>
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  On mobile devices, we request usage access permission to track your screen time and app usage. This data remains private and is only used to provide you with insights into your device usage patterns. You can revoke this permission at any time through your device settings.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-cyan-500"></span>
                  Managing Permissions
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  You have full control over permissions. You can grant or revoke any permission through your device settings at any time. Note that some features may not function properly without their required permissions.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                  No Unnecessary Access
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  We do not request access to your contacts, microphone, camera, or location unless explicitly required for a specific feature you choose to use. We respect your privacy and only ask for permissions that are essential to the app's functionality.
                </p>
              </div>
            </div>
          </div>

          <div className="text-[10px] text-zinc-700 text-center pt-2">
            Last updated: December 2025
          </div>
        </div>
      </div>
    </div>
  );
}