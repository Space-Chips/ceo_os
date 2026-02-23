import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { ArrowLeft } from 'lucide-react';
import { useLanguage } from '../components/LanguageProvider';

export default function SettingsPrivacy() {
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
            {t('privacyPolicy')}
          </h1>
          
          <div className="w-20" />
        </div>

        <div className="space-y-6">
          <div className="relative">
            <div className="relative p-5 rounded-xl bg-zinc-900/60 border border-zinc-800/50 shadow-[0_8px_32px_rgba(0,0,0,0.4)]">
              <p className="text-zinc-400 text-sm leading-relaxed">
                This privacy policy explains how we collect, use, and protect your personal information when you use our productivity application.
              </p>
            </div>
          </div>

          <div className="space-y-5">
            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  Information We Collect
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  We collect information you provide directly to us, including your email address, name, and productivity data such as habits, tasks, and screen time usage. This information is necessary to provide you with the app's core functionality.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  How We Use Your Information
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  Your data is used solely to provide and improve the app's services. We use your productivity data to generate insights, track progress, and help you achieve your goals. We do not sell your personal information to third parties.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  Data Storage and Security
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  Your data is stored securely on our servers with industry-standard encryption. We implement appropriate technical and organizational measures to protect your information against unauthorized access, alteration, or destruction.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  Data Sharing
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  We do not share your personal information with third parties except when required by law or with your explicit consent. Analytics and performance data may be shared in aggregated, anonymized form.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  Your Rights
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  You have the right to access, correct, or delete your personal information at any time. You can also request a copy of your data or restrict how we use it. To exercise these rights, please contact us through the Contact section.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  Changes to This Policy
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  We may update this privacy policy from time to time. We will notify you of any significant changes by email or through the app. Your continued use of the app after such changes constitutes acceptance of the updated policy.
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