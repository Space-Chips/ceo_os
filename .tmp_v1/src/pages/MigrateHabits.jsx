import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, RefreshCw, CheckCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function MigrateHabits() {
  const queryClient = useQueryClient();
  const [migrationDone, setMigrationDone] = useState(false);

  const { data: habits } = useQuery({
    queryKey: ['allHabitsForMigration'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.Habit.filter({ 
        created_by: user.email,
        archived: false 
      });
    }
  });

  const migrateMutation = useMutation({
    mutationFn: async () => {
      if (!habits) return;
      
      for (const habit of habits) {
        if (!habit.specific_days || habit.specific_days.length === 0) continue;
        
        // Check if it's using old format (0-6)
        const hasOldFormat = habit.specific_days.some(d => d >= 0 && d <= 6);
        const hasNewFormat = habit.specific_days.some(d => d >= 1 && d <= 7);
        
        // If it has 0 or all numbers are 0-6, it's old format
        if (hasOldFormat && !hasNewFormat) {
          // Convert: 0→7, 1→1, 2→2, ..., 6→6
          const newDays = habit.specific_days.map(day => day === 0 ? 7 : day);
          
          await base44.entities.Habit.update(habit.id, {
            specific_days: newDays
          });
        }
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['allHabitsForMigration']);
      queryClient.invalidateQueries(['allHabits']);
      queryClient.invalidateQueries(['habits']);
      setMigrationDone(true);
    }
  });

  const needsMigration = habits?.some(habit => {
    if (!habit.specific_days || habit.specific_days.length === 0) return false;
    return habit.specific_days.includes(0);
  });

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6">
      <div className="max-w-2xl mx-auto">
        <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-500 hover:text-zinc-300 mb-8 transition-colors">
          <ArrowLeft className="w-4 h-4" />
          <span className="text-sm font-medium">Home</span>
        </Link>

        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-white via-zinc-200 to-zinc-400 bg-clip-text text-transparent">
            Migrate Habits
          </h1>
          <p className="text-zinc-500 text-sm mt-2">Fix day numbering for existing habits</p>
        </div>

        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-600/10 to-purple-600/10 rounded-2xl blur-xl" />
          <div className="relative p-8 rounded-2xl bg-gradient-to-br from-zinc-900 via-zinc-800 to-zinc-900 border border-zinc-700/50">
            {migrationDone ? (
              <div className="text-center">
                <CheckCircle className="w-16 h-16 text-green-500 mx-auto mb-4" />
                <h2 className="text-xl font-bold mb-2">Migration Complete!</h2>
                <p className="text-zinc-400 mb-6">
                  Your habits have been updated. You can now go back to the Dashboard.
                </p>
                <Link to={createPageUrl('Dashboard')}>
                  <Button className="bg-white text-black hover:bg-zinc-200">
                    Go to Dashboard
                  </Button>
                </Link>
              </div>
            ) : (
              <>
                <div className="mb-6">
                  <h2 className="text-lg font-bold mb-3">Why this is needed:</h2>
                  <ul className="space-y-2 text-sm text-zinc-400">
                    <li>• Old habits were stored with Sunday=0, Monday=1, etc.</li>
                    <li>• New system uses Monday=1, Tuesday=2, ..., Sunday=7</li>
                    <li>• This migration updates your existing habits to the new format</li>
                  </ul>
                </div>

                {habits && (
                  <div className="mb-6 p-4 rounded-lg bg-zinc-900/50 border border-zinc-800">
                    <div className="text-sm text-zinc-400 mb-2">
                      Found {habits.length} habits
                    </div>
                    {needsMigration ? (
                      <div className="text-sm text-yellow-400">
                        ⚠️ {habits.filter(h => h.specific_days?.includes(0)).length} habits need migration
                      </div>
                    ) : (
                      <div className="text-sm text-green-400">
                        ✓ All habits are up to date
                      </div>
                    )}
                  </div>
                )}

                <Button
                  onClick={() => migrateMutation.mutate()}
                  disabled={migrateMutation.isPending || !needsMigration}
                  className="w-full bg-white text-black hover:bg-zinc-200"
                >
                  {migrateMutation.isPending ? (
                    <>
                      <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                      Migrating...
                    </>
                  ) : needsMigration ? (
                    'Migrate Habits'
                  ) : (
                    'No Migration Needed'
                  )}
                </Button>

                {!needsMigration && (
                  <p className="text-center text-xs text-zinc-600 mt-4">
                    Your habits are already using the correct format
                  </p>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}