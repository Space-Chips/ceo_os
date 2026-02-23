import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, Plus, Trash2, Shield, Globe, Coffee, Play } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useLanguage } from '../components/LanguageProvider';
import AddTimeModal from '../components/blocking/AddTimeModal';
import RestPeriodModal from '../components/blocking/RestPeriodModal';
import RestPeriodActivation from '../components/blocking/RestPeriodActivation';
import { format, parseISO, isBefore, isAfter } from 'date-fns';

export default function ScreenTime() {
  const { t } = useLanguage();
  const queryClient = useQueryClient();
  const [showAddApp, setShowAddApp] = useState(false);
  const [showAddWebsite, setShowAddWebsite] = useState(false);
  const [showAddTimeModal, setShowAddTimeModal] = useState(null);
  const [showRestPeriodModal, setShowRestPeriodModal] = useState(false);
  const [activatingRestPeriod, setActivatingRestPeriod] = useState(null);
  const [newAppName, setNewAppName] = useState('');
  const [newWebsiteUrl, setNewWebsiteUrl] = useState('');

  const { data: blockedApps } = useQuery({
    queryKey: ['blockedApps'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.BlockedApp.filter({ created_by: user.email });
    },
    initialData: []
  });

  const { data: blockedWebsites } = useQuery({
    queryKey: ['blockedWebsites'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.BlockedWebsite.filter({ created_by: user.email });
    },
    initialData: []
  });

  const { data: restPeriods } = useQuery({
    queryKey: ['restPeriods'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.RestPeriod.filter({ created_by: user.email });
    },
    initialData: []
  });

  const { data: isInFocusMode } = useQuery({
    queryKey: ['isInFocusMode'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const sessions = await base44.entities.FocusSession.filter({
        created_by: user.email,
        completed: false,
        early_exit: false
      });
      return sessions.length > 0;
    }
  });

  const createAppMutation = useMutation({
    mutationFn: async (appName) => {
      const user = await base44.auth.me();
      return await base44.entities.BlockedApp.create({
        app_name: appName,
        time_limit_minutes: 0,
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['blockedApps']);
      setNewAppName('');
      setShowAddApp(false);
    }
  });

  const createWebsiteMutation = useMutation({
    mutationFn: async (url) => {
      const user = await base44.auth.me();
      return await base44.entities.BlockedWebsite.create({
        url_domain: url,
        time_limit_minutes: 0,
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['blockedWebsites']);
      setNewWebsiteUrl('');
      setShowAddWebsite(false);
    }
  });

  const deleteAppMutation = useMutation({
    mutationFn: async (id) => {
      await base44.entities.BlockedApp.delete(id);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['blockedApps']);
    }
  });

  const deleteWebsiteMutation = useMutation({
    mutationFn: async (id) => {
      await base44.entities.BlockedWebsite.delete(id);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['blockedWebsites']);
    }
  });

  const updateTimeLimitMutation = useMutation({
    mutationFn: async ({ id, minutes, type }) => {
      if (type === 'app') {
        const app = blockedApps.find(a => a.id === id);
        await base44.entities.BlockedApp.update(id, {
          time_limit_minutes: (app.time_limit_minutes || 0) + minutes
        });
      } else {
        const site = blockedWebsites.find(s => s.id === id);
        await base44.entities.BlockedWebsite.update(id, {
          time_limit_minutes: (site.time_limit_minutes || 0) + minutes
        });
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['blockedApps']);
      queryClient.invalidateQueries(['blockedWebsites']);
    }
  });

  const handleAddTime = (minutes) => {
    if (showAddTimeModal) {
      updateTimeLimitMutation.mutate({
        id: showAddTimeModal.id,
        minutes: minutes,
        type: showAddTimeModal.type
      });
      setShowAddTimeModal(null);
    }
  };

  const scheduleRestPeriodMutation = useMutation({
    mutationFn: async (data) => {
      const user = await base44.auth.me();
      return await base44.entities.RestPeriod.create({
        ...data,
        status: 'scheduled',
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['restPeriods']);
      setShowRestPeriodModal(false);
    }
  });

  const activateRestPeriodMutation = useMutation({
    mutationFn: async (periodId) => {
      await base44.entities.RestPeriod.update(periodId, {
        status: 'active',
        activated_at: new Date().toISOString()
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['restPeriods']);
      setActivatingRestPeriod(null);
    }
  });

  const cancelRestPeriodMutation = useMutation({
    mutationFn: async (periodId) => {
      await base44.entities.RestPeriod.update(periodId, {
        status: 'cancelled'
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['restPeriods']);
    }
  });

  const handleScheduleRestPeriod = (data) => {
    scheduleRestPeriodMutation.mutate(data);
  };

  const handleActivateRestPeriod = (period) => {
    setActivatingRestPeriod(period);
  };

  const handleConfirmActivation = () => {
    if (activatingRestPeriod) {
      activateRestPeriodMutation.mutate(activatingRestPeriod.id);
    }
  };

  const handleCancelActivation = () => {
    setActivatingRestPeriod(null);
  };

  const now = new Date();
  const scheduledRestPeriods = restPeriods?.filter(p => {
    if (p.status !== 'scheduled') return false;
    const startTime = parseISO(p.scheduled_start_time);
    return isBefore(now, startTime) || (isBefore(startTime, now) && isBefore(now, new Date(startTime.getTime() + 10 * 60 * 1000)));
  }) || [];

  const activeRestPeriod = restPeriods?.find(p => p.status === 'active');

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 pb-12 relative overflow-hidden">
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-2xl mx-auto relative">
        <div className="flex items-center justify-between mb-6">
          <Link to={createPageUrl('ScreenTimeManager')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">{t('back')}</span>
          </Link>
          
          <h1 className="text-xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('blockApps')} & {t('blockWebsites')}
          </h1>
          
          <div className="w-20" />
        </div>

        {/* Blocked Apps Section */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-black text-zinc-300 tracking-tight flex items-center gap-2">
              <div className="w-10 h-10 rounded-xl relative">
                {/* Base noire mate avec relief */}
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
                {/* Icône mobile avec accent rouge */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
                    <rect x="6" y="3" width="12" height="18" rx="2.5" 
                          stroke="#ef4444" strokeWidth="2"/>
                    <line x1="9" y1="18" x2="15" y2="18" 
                          stroke="#ef4444" strokeWidth="2" strokeLinecap="round"/>
                  </svg>
                </div>
              </div>
              {t('blockApps')}
            </h2>
            <button
              onClick={() => setShowAddApp(true)}
              className="px-3 py-2 rounded-lg bg-white text-black text-xs font-bold hover:bg-zinc-200 active:scale-95 transition-all duration-150 flex items-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" />
              {t('add')}
            </button>
          </div>

          {showAddApp && (
            <div className="mb-4 p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/50">
              <Input
                value={newAppName}
                onChange={(e) => setNewAppName(e.target.value)}
                placeholder="App name (e.g., Instagram, TikTok)"
                className="mb-3 bg-zinc-900 border-zinc-800"
                onKeyPress={(e) => {
                  if (e.key === 'Enter' && newAppName.trim()) {
                    createAppMutation.mutate(newAppName.trim());
                  }
                }}
              />
              <div className="flex gap-2">
                <Button
                  onClick={() => createAppMutation.mutate(newAppName.trim())}
                  disabled={!newAppName.trim() || createAppMutation.isPending}
                  className="flex-1 bg-white text-black hover:bg-zinc-200 h-9 text-xs font-bold"
                >
                  {t('add')}
                </Button>
                <Button
                  onClick={() => {
                    setShowAddApp(false);
                    setNewAppName('');
                  }}
                  variant="outline"
                  className="px-4 h-9 text-xs"
                >
                  {t('cancel')}
                </Button>
              </div>
            </div>
          )}

          <div className="space-y-2">
            {blockedApps?.map(app => (
              <div key={app.id} className="group flex items-center gap-3 p-4 rounded-xl bg-red-500/5 border-2 border-red-500/30 hover:border-red-500/40 transition-all">
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-semibold text-white truncate">{app.app_name}</div>
                  <div className="text-xs text-zinc-600">
                    {app.time_limit_minutes > 0 ? `${app.time_limit_minutes} min remaining` : 'Fully blocked'}
                  </div>
                </div>
                <button
                  onClick={() => setShowAddTimeModal({ id: app.id, name: app.app_name, type: 'app' })}
                  className="px-3 py-1.5 rounded-lg bg-zinc-800/60 hover:bg-zinc-700/60 text-xs font-bold text-zinc-400 hover:text-zinc-300 transition-all active:scale-95"
                >
                  + Time
                </button>
                <button
                  onClick={() => deleteAppMutation.mutate(app.id)}
                  className="p-2 hover:bg-red-950/30 rounded-lg transition-all active:scale-95 opacity-0 group-hover:opacity-100"
                >
                  <Trash2 className="w-4 h-4 text-red-500/70" />
                </button>
              </div>
            ))}
            {(!blockedApps || blockedApps.length === 0) && !showAddApp && (
              <div className="text-center py-8 text-zinc-600 text-sm">
                No blocked apps yet
              </div>
            )}
          </div>
        </div>

        {/* Blocked Websites Section */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-black text-zinc-300 tracking-tight flex items-center gap-2">
              <div className="w-10 h-10 rounded-xl relative">
                {/* Base noire mate avec relief */}
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
                {/* Icône globe avec accent rouge */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="9" 
                            stroke="#ef4444" strokeWidth="2"/>
                    <path d="M12 3c-2.5 3-2.5 15 0 18M12 3c2.5 3 2.5 15 0 18M3 12h18" 
                          stroke="#ef4444" strokeWidth="2" strokeLinecap="round"/>
                  </svg>
                </div>
              </div>
              {t('blockWebsites')}
            </h2>
            <button
              onClick={() => setShowAddWebsite(true)}
              className="px-3 py-2 rounded-lg bg-white text-black text-xs font-bold hover:bg-zinc-200 active:scale-95 transition-all duration-150 flex items-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" />
              {t('add')}
            </button>
          </div>

          {showAddWebsite && (
            <div className="mb-4 p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/50">
              <Input
                value={newWebsiteUrl}
                onChange={(e) => setNewWebsiteUrl(e.target.value)}
                placeholder="Domain (e.g., twitter.com, youtube.com)"
                className="mb-3 bg-zinc-900 border-zinc-800"
                onKeyPress={(e) => {
                  if (e.key === 'Enter' && newWebsiteUrl.trim()) {
                    createWebsiteMutation.mutate(newWebsiteUrl.trim());
                  }
                }}
              />
              <div className="flex gap-2">
                <Button
                  onClick={() => createWebsiteMutation.mutate(newWebsiteUrl.trim())}
                  disabled={!newWebsiteUrl.trim() || createWebsiteMutation.isPending}
                  className="flex-1 bg-white text-black hover:bg-zinc-200 h-9 text-xs font-bold"
                >
                  {t('add')}
                </Button>
                <Button
                  onClick={() => {
                    setShowAddWebsite(false);
                    setNewWebsiteUrl('');
                  }}
                  variant="outline"
                  className="px-4 h-9 text-xs"
                >
                  {t('cancel')}
                </Button>
              </div>
            </div>
          )}

          <div className="space-y-2">
            {blockedWebsites?.map(site => (
              <div key={site.id} className="group flex items-center gap-3 p-4 rounded-xl bg-red-500/5 border-2 border-red-500/30 hover:border-red-500/40 transition-all">
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-semibold text-white truncate">{site.url_domain}</div>
                  <div className="text-xs text-zinc-600">
                    {site.time_limit_minutes > 0 ? `${site.time_limit_minutes} min remaining` : 'Fully blocked'}
                  </div>
                </div>
                <button
                  onClick={() => setShowAddTimeModal({ id: site.id, name: site.url_domain, type: 'website' })}
                  className="px-3 py-1.5 rounded-lg bg-zinc-800/60 hover:bg-zinc-700/60 text-xs font-bold text-zinc-400 hover:text-zinc-300 transition-all active:scale-95"
                >
                  + Time
                </button>
                <button
                  onClick={() => deleteWebsiteMutation.mutate(site.id)}
                  className="p-2 hover:bg-red-950/30 rounded-lg transition-all active:scale-95 opacity-0 group-hover:opacity-100"
                >
                  <Trash2 className="w-4 h-4 text-red-500/70" />
                </button>
              </div>
            ))}
            {(!blockedWebsites || blockedWebsites.length === 0) && !showAddWebsite && (
              <div className="text-center py-8 text-zinc-600 text-sm">
                No blocked websites yet
              </div>
            )}
          </div>
        </div>

        {/* Rest Periods Section */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-black text-zinc-300 tracking-tight flex items-center gap-2">
              <div className="w-10 h-10 rounded-xl relative">
                {/* Base noire mate avec relief */}
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
                {/* Icône pause/relax avec accent rouge */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="9" 
                            stroke="#ef4444" strokeWidth="2"/>
                    <rect x="9" y="8" width="2" height="8" rx="1" 
                          fill="#ef4444"/>
                    <rect x="13" y="8" width="2" height="8" rx="1" 
                          fill="#ef4444"/>
                  </svg>
                </div>
              </div>
              {t('restPeriod')}
            </h2>
            <button
              onClick={() => setShowRestPeriodModal(true)}
              className="px-3 py-2 rounded-lg bg-white text-black text-xs font-bold hover:bg-zinc-200 active:scale-95 transition-all duration-150 flex items-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" />
              Break
            </button>
          </div>

          {activeRestPeriod && (
            <div className="mb-4 p-4 rounded-xl bg-gradient-to-br from-blue-950/40 to-cyan-950/40 border border-blue-700/50">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-blue-500/20 border border-blue-500/40 flex items-center justify-center">
                  <Coffee className="w-5 h-5 text-blue-400 animate-pulse" />
                </div>
                <div className="flex-1">
                  <div className="text-sm font-bold text-blue-300">Active Rest Period</div>
                  <div className="text-xs text-blue-400/60">{activeRestPeriod.reason}</div>
                  <div className="text-xs text-blue-500/70 mt-1">{activeRestPeriod.duration_minutes} minutes - All restrictions paused</div>
                </div>
              </div>
            </div>
          )}

          <div className="space-y-2">
            {scheduledRestPeriods.map(period => {
              const startTime = parseISO(period.scheduled_start_time);
              const canActivateNow = isBefore(startTime, now);
              
              return (
                <div key={period.id} className="group flex items-center gap-3 p-4 rounded-xl bg-zinc-900/40 border border-zinc-800/40 hover:border-zinc-700/50 transition-all">
                  <div className="w-10 h-10 rounded-lg bg-blue-950/40 border border-blue-900/40 flex items-center justify-center shadow-[inset_0_2px_4px_rgba(0,0,0,0.3)]">
                    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
                      <circle cx="12" cy="12" r="8" fill="#1E3A8A" stroke="#3B82F6" strokeWidth="1.3"/>
                      <path d="M9 11C9 9.5 10 8.5 11.5 8.5H12.5C14 8.5 15 9.5 15 11C15 12 14 13 12.5 13.5H11.5C10 14 9 15 9 16.5C9 18 10 19 11.5 19H12.5C14 19 15 18 15 16.5" stroke="#93C5FD" strokeWidth="1.6" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-semibold text-white truncate">{period.reason}</div>
                    <div className="text-xs text-zinc-600">
                      {format(startTime, 'MMM d, h:mm a')} • {period.duration_minutes} min
                    </div>
                  </div>
                  {canActivateNow ? (
                    <button
                      onClick={() => handleActivateRestPeriod(period)}
                      className="px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-xs font-bold text-white transition-all active:scale-95 flex items-center gap-1"
                    >
                      <Play className="w-3 h-3" />
                      Start
                    </button>
                  ) : (
                    <div className="text-xs text-zinc-600 px-3">
                      Scheduled
                    </div>
                  )}
                  <button
                    onClick={() => cancelRestPeriodMutation.mutate(period.id)}
                    className="p-2 hover:bg-red-950/30 rounded-lg transition-all active:scale-95 opacity-0 group-hover:opacity-100"
                  >
                    <Trash2 className="w-4 h-4 text-red-500/70" />
                  </button>
                </div>
              );
            })}
            {scheduledRestPeriods.length === 0 && (
              <div className="text-center py-8 text-zinc-600 text-sm">
                No scheduled breaks. Schedule breaks at least 2 hours in advance.
              </div>
            )}
          </div>
        </div>
      </div>

      {showAddTimeModal && (
        <AddTimeModal
          entityName={showAddTimeModal.name}
          entityType={showAddTimeModal.type}
          onAddTime={handleAddTime}
          onClose={() => setShowAddTimeModal(null)}
        />
      )}

      <RestPeriodModal
        open={showRestPeriodModal}
        onClose={() => setShowRestPeriodModal(false)}
        onSchedule={handleScheduleRestPeriod}
        isInFocusMode={isInFocusMode || false}
      />

      {activatingRestPeriod && (
        <RestPeriodActivation
          restPeriod={activatingRestPeriod}
          onConfirm={handleConfirmActivation}
          onCancel={handleCancelActivation}
        />
      )}
    </div>
  );
}