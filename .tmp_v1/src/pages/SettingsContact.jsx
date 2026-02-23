import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { ArrowLeft, Mail } from 'lucide-react';
import { useLanguage } from '../components/LanguageProvider';

export default function SettingsContact() {
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
            {t('contact')}
          </h1>
          
          <div className="w-20" />
        </div>

        <div className="space-y-6">
          <div className="relative">
            <div className="relative p-5 rounded-xl bg-zinc-900/60 border border-zinc-800/50 shadow-[0_8px_32px_rgba(0,0,0,0.4)]">
              <p className="text-zinc-400 text-sm leading-relaxed">
                We're here to help! If you have questions, feedback, or need support, please reach out to us through the methods below.
              </p>
            </div>
          </div>

          <div className="space-y-5">
            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  General Inquiries
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  For general questions about the app, features, or your account, please contact us via email. We typically respond within 24-48 hours.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                  Technical Support
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed mb-3">
                  If you're experiencing technical issues, please include the following information in your message:
                </p>
                <ul className="space-y-2 text-zinc-400 text-xs">
                  <li className="flex items-start gap-2">
                    <span className="text-zinc-700 mt-1">•</span>
                    <span>Device type and operating system version</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-zinc-700 mt-1">•</span>
                    <span>App version (if available)</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-zinc-700 mt-1">•</span>
                    <span>Description of the issue</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-zinc-700 mt-1">•</span>
                    <span>Steps to reproduce the problem</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-zinc-700 mt-1">•</span>
                    <span>Screenshots (if applicable)</span>
                  </li>
                </ul>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-purple-500"></span>
                  Privacy and Data Requests
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  For privacy-related inquiries, data access requests, or data deletion requests, please contact us with your registered email address. We will respond to your request in accordance with applicable data protection laws.
                </p>
              </div>
            </div>

            <div className="relative">
              <div className="relative p-5 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
                <h2 className="text-white text-sm font-bold mb-3 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>
                  Feedback and Suggestions
                </h2>
                <p className="text-zinc-400 text-xs leading-relaxed">
                  We value your feedback! If you have ideas for new features or improvements, we'd love to hear from you. Your input helps us make the app better for everyone.
                </p>
              </div>
            </div>
          </div>

          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/10 to-purple-500/10 rounded-2xl blur-xl" />
            <div className="relative p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/50 shadow-[0_12px_48px_rgba(0,0,0,0.5)]">
              <div className="flex items-center gap-4 mb-4">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-lg">
                  <Mail className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-white mb-1">Email Support</h3>
                  <p className="text-xs text-zinc-500">We typically respond within 24-48 hours</p>
                </div>
              </div>
              <a
                href="mailto:support@app.com"
                className="block w-full text-center py-3 px-4 rounded-xl bg-white/10 hover:bg-white/15 border border-white/10 text-white font-medium text-sm transition-all duration-150 active:scale-[0.98]"
              >
                support@app.com
              </a>
            </div>
          </div>

          <div className="text-xs text-zinc-600 text-center">
            Response times may vary during weekends and holidays
          </div>
        </div>
      </div>
    </div>
  );
}