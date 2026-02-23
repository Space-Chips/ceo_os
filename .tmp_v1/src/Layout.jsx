import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from './utils';
import { base44 } from '@/api/base44Client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { User, FileText, Shield, BarChart3, X, ClipboardList, CheckSquare, Calendar as CalendarIcon } from 'lucide-react';
import { LanguageProvider, useLanguage } from './components/LanguageProvider';
import { RankAmbientProvider, useRankAmbient } from './components/RankAmbientProvider';
import { PremiumProvider } from './components/PremiumProvider';

export default function Layout({ children, currentPageName }) {
  return (
    <LanguageProvider>
      <RankAmbientProvider>
        <PremiumProvider>
          <LayoutContent children={children} currentPageName={currentPageName} />
        </PremiumProvider>
      </RankAmbientProvider>
    </LanguageProvider>
  );
}

function LayoutContent({ children, currentPageName }) {
  const { t } = useLanguage();
  const { ambientStyles } = useRankAmbient();
  const [showMenu, setShowMenu] = useState(false);
  const [user, setUser] = useState(null);
  const queryClient = useQueryClient();

  const { data: appSettings } = useQuery({
    queryKey: ['appSettings'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const settings = await base44.entities.AppSettings.filter({ created_by: user.email });
      if (settings.length === 0) {
        const newSettings = await base44.entities.AppSettings.create({
          active_apps: ['Pareto', 'Habits', 'Calendar', 'ScreenTimeManager']
        });
        return newSettings;
      }
      return settings[0];
    },
    staleTime: 0,
    cacheTime: 0
  });

  const toggleAppMutation = useMutation({
    mutationFn: async (appName) => {
      if (!appSettings) return;
      const currentApps = appSettings.active_apps || [];
      const newApps = currentApps.includes(appName)
        ? currentApps.filter(a => a !== appName)
        : [...currentApps, appName];
      await base44.entities.AppSettings.update(appSettings.id, { active_apps: newApps });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['appSettings']);
    }
  });

  const availableApps = [
    { id: 'Pareto', name: t('todo'), icon: ClipboardList },
    { id: 'Habits', name: t('habits'), icon: CheckSquare },
    { id: 'Calendar', name: t('schedule'), icon: CalendarIcon },
    { id: 'ScreenTimeManager', name: t('screenTime'), icon: Shield }
  ];

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {});
  }, []);

  if (currentPageName === 'Home') {
    return (
      <div className="min-h-screen bg-black text-white relative overflow-hidden">
        {/* Cadre selon le rang */}
        {ambientStyles.frame}
        
        {/* User Icon - Top Left */}
        <button
          onClick={() => setShowMenu(true)}
          className="fixed top-6 left-6 z-50 w-11 h-11 rounded-full bg-gradient-to-br from-zinc-800 via-zinc-700 to-zinc-800 flex items-center justify-center shadow-lg border border-zinc-700/50 hover:scale-105 transition-transform"
        >
          <span className="text-sm font-bold bg-gradient-to-br from-white to-zinc-300 bg-clip-text text-transparent">
            {user?.full_name?.charAt(0) || '?'}
          </span>
        </button>

        {/* Slide-in Menu */}
        {showMenu && (
          <>
            <div
              className="fixed inset-0 bg-black/80 z-50"
              onClick={() => setShowMenu(false)}
            />
            <div className="fixed left-0 top-0 bottom-0 w-80 bg-gradient-to-b from-zinc-900 via-zinc-950 to-black border-r border-zinc-800 z-50 p-6 overflow-y-auto">
              <button
                onClick={() => setShowMenu(false)}
                className="absolute top-6 right-6 p-2 hover:bg-zinc-800 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>

              <div className="mb-8">
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-zinc-800 via-zinc-700 to-zinc-800 flex items-center justify-center shadow-lg border border-zinc-700/50 mb-4">
                  <span className="text-2xl font-bold bg-gradient-to-br from-white to-zinc-300 bg-clip-text text-transparent">
                    {user?.full_name?.charAt(0) || '?'}
                  </span>
                </div>
                <div className="text-xl font-bold mb-1">{user?.full_name || 'User'}</div>
                <div className="text-sm text-zinc-500">{user?.email}</div>
              </div>

              <div className="space-y-3">
                <Link
                  to={createPageUrl('Notes')}
                  onClick={() => setShowMenu(false)}
                  className="group flex items-center gap-3 p-4 rounded-xl bg-zinc-900/50 border border-zinc-800/50 hover:border-indigo-500/30 hover:bg-zinc-900/70 active:scale-[0.98] transition-all duration-150 relative overflow-hidden"
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-indigo-500/0 via-indigo-500/5 to-indigo-500/0 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  <div className="w-10 h-10 group-active:scale-[0.96] transition-transform duration-100 relative">
                    <div className="absolute inset-0 rounded-[11px]"
                         style={{
                           background: '#2e2e2e',
                           boxShadow: `
                             0 1.5px 4px rgba(0, 0, 0, 0.35),
                             inset 0 0.5px 0.5px rgba(255, 255, 255, 0.03),
                             inset 0 -0.5px 0.5px rgba(0, 0, 0, 0.15)
                           `
                         }}
                    />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <svg className="w-[54%] h-[54%]" viewBox="0 0 24 24" fill="none">
                        <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8l-6-6z" 
                              stroke="#6366f1" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
                        <path d="M14 2v6h6M16 13H8M16 17H8M10 9H8" 
                              stroke="#6366f1" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
                      </svg>
                    </div>
                  </div>
                  <div className="text-left flex-1">
                    <div className="font-semibold">Notes</div>
                    <div className="text-xs text-zinc-500">Your quick notes</div>
                  </div>
                </Link>

                <Link
                  to={createPageUrl('BiannualReport')}
                  onClick={() => setShowMenu(false)}
                  className="flex items-center gap-3 p-4 rounded-lg bg-zinc-900/50 border border-zinc-800 hover:border-zinc-700 transition-all"
                >
                  <div className="w-10 h-10 rounded-xl relative">
                    <div className="absolute inset-0 rounded-xl"
                         style={{
                           background: '#2e2e2e',
                           boxShadow: `
                             0 2px 6px rgba(0, 0, 0, 0.35),
                             inset 0 1px 1px rgba(255, 255, 255, 0.03),
                             inset 0 -1px 1px rgba(0, 0, 0, 0.15)
                           `
                         }}
                    />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <svg className="w-[54%] h-[54%]" viewBox="0 0 24 24" fill="none">
                        <rect x="3" y="3" width="18" height="18" rx="2.5" 
                              stroke="#6366f1" strokeWidth="1.8"/>
                        <rect x="6.5" y="13" width="2.5" height="7" rx="0.5"
                              fill="#6366f1"/>
                        <rect x="10.5" y="7" width="2.5" height="13" rx="0.5"
                              fill="#6366f1"/>
                        <rect x="14.5" y="10" width="2.5" height="10" rx="0.5"
                              fill="#6366f1"/>
                      </svg>
                    </div>
                  </div>
                  <div>
                    <div className="font-semibold">{t('sixMonthReport')}</div>
                    <div className="text-xs text-zinc-500">{t('yourProgressOverview')}</div>
                  </div>
                </Link>
              </div>

              <div className="space-y-2">
                <div className="text-xs text-zinc-500 uppercase tracking-wide font-semibold mb-2 px-2">{t('activeApps')}</div>
                {availableApps.map(app => {
                  const currentApps = appSettings?.active_apps || [];
                  const isActive = currentApps.includes(app.id);
                  const Icon = app.icon;
                  return (
                    <button
                      key={app.id}
                      onClick={() => toggleAppMutation.mutate(app.id)}
                      className={`w-full flex items-center gap-3 p-3 rounded-lg border transition-all ${
                        isActive
                          ? 'bg-zinc-900/50 border-zinc-700 hover:border-zinc-600'
                          : 'bg-zinc-950/50 border-zinc-800 opacity-50 hover:opacity-100'
                      }`}
                    >
                      <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-zinc-600'}`} />
                      <div className="text-left flex-1">
                        <div className={`text-sm font-medium ${isActive ? 'text-white' : 'text-zinc-600'}`}>
                          {app.name}
                        </div>
                      </div>
                      <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                        isActive ? 'border-green-500 bg-green-500' : 'border-zinc-700'
                      }`}>
                        {isActive && <div className="w-2 h-2 rounded-full bg-white" />}
                      </div>
                    </button>
                  );
                })}
              </div>

              <div className="space-y-2">
                <Link
                  to={createPageUrl('Settings')}
                  onClick={() => setShowMenu(false)}
                  className="w-full flex items-center gap-3 p-4 rounded-lg bg-zinc-900/50 border border-zinc-800 hover:border-zinc-700 transition-all"
                >
                  <div className="w-10 h-10 rounded-xl relative">
                    <div className="absolute inset-0 rounded-xl"
                         style={{
                           background: '#2e2e2e',
                           boxShadow: `
                             0 2px 6px rgba(0, 0, 0, 0.35),
                             inset 0 1px 1px rgba(255, 255, 255, 0.03),
                             inset 0 -1px 1px rgba(0, 0, 0, 0.15)
                           `
                         }}
                    />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <svg className="w-[56%] h-[56%]" viewBox="0 0 24 24" fill="none">
                        <circle cx="12" cy="12" r="3.5" 
                                stroke="#6366f1" strokeWidth="2"/>
                        <path d="M12 1v6m0 6v10M23 12h-6m-6 0H1" 
                              stroke="#6366f1" strokeWidth="1.8" 
                              strokeLinecap="round"/>
                        <path d="M4.5 4.5l4 4m7 7l4 4M19.5 4.5l-4 4m-7 7l-4 4" 
                              stroke="#6366f1" strokeWidth="1.6" 
                              strokeLinecap="round"/>
                      </svg>
                    </div>
                  </div>
                  <div className="text-left">
                    <div className="font-semibold">{t('settingsAndLegal')}</div>
                    <div className="text-xs text-zinc-500">{t('termsAndConditions')}</div>
                  </div>
                </Link>
              </div>

              <div className="mt-8 pt-8 border-t border-zinc-800">
                <button
                  onClick={() => base44.auth.logout()}
                  className="w-full p-3 rounded-lg bg-red-950/30 border border-red-900/50 text-red-400 hover:bg-red-950/50 transition-colors"
                >
                  {t('logout')}
                </button>
              </div>
            </div>
          </>
        )}

        {children}
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black text-white relative overflow-hidden">
      {ambientStyles.frame}
      {children}
    </div>
  );
}