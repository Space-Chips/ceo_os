import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { ArrowLeft, Globe, Shield, FileText, Trash2, Mail } from 'lucide-react';
import { useLanguage } from '../components/LanguageProvider';

export default function Settings() {
  const { t } = useLanguage();

  const sections = [
    { id: 'language', icon: Globe, label: t('language'), page: 'SettingsLanguage' },
    { id: 'privacy', icon: Shield, label: t('privacyPolicy'), page: 'SettingsPrivacy' },
    { id: 'permissions', icon: Shield, label: t('permissions'), page: 'SettingsPermissions' },
    { id: 'terms', icon: FileText, label: t('termsOfUse'), page: 'SettingsTerms' },
    { id: 'deletion', icon: Trash2, label: t('dataDeletion'), page: 'SettingsDeletion' },
    { id: 'contact', icon: Mail, label: t('contact'), page: 'SettingsContact' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 relative overflow-hidden">
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-2xl mx-auto relative">
        <div className="flex items-center justify-between mb-6">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">{t('back')}</span>
          </Link>
          
          <h1 className="text-2xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('settings')}
          </h1>
          
          <div className="w-20" />
        </div>

        <div className="space-y-2">
          {sections.map((section) => (
            <Link
              key={section.id}
              to={createPageUrl(section.page)}
              className="group block relative"
            >
              <div className="relative p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/50 hover:border-zinc-700/60 hover:bg-zinc-900/80 active:scale-[0.98] transition-all duration-150 shadow-[0_8px_24px_rgba(0,0,0,0.4)]">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg bg-zinc-800/60 flex items-center justify-center shadow-[inset_0_2px_4px_rgba(0,0,0,0.4)]">
                    <section.icon className="w-5 h-5 text-zinc-400" />
                  </div>
                  <div className="flex-1">
                    <div className="text-sm font-semibold text-white">{section.label}</div>
                  </div>
                  <ArrowLeft className="w-4 h-4 text-zinc-600 rotate-180 group-hover:text-zinc-400 transition-colors" />
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}