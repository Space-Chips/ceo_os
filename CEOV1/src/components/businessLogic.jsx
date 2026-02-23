import { base44 } from '@/api/base44Client';
import { format, startOfDay, endOfDay, subDays, differenceInMinutes, parseISO, addMinutes, startOfWeek, endOfWeek, addDays } from 'date-fns';

export const RANK_TIERS = [
  { level: 1, name: 'Panda', icon: '🐼', minScreenTimeMinutes: 999999, maxScreenTimeMinutes: 999999 },
  { level: 2, name: 'Soldier', icon: '🪖', minScreenTimeMinutes: 480, maxScreenTimeMinutes: 999999 },
  { level: 3, name: 'Warrior', icon: '⚔️', minScreenTimeMinutes: 360, maxScreenTimeMinutes: 479 },
  { level: 4, name: 'Knight', icon: '🛡️', minScreenTimeMinutes: 300, maxScreenTimeMinutes: 359 },
  { level: 5, name: 'Captain', icon: '🎖️', minScreenTimeMinutes: 240, maxScreenTimeMinutes: 299 },
  { level: 6, name: 'Commander', icon: '⭐', minScreenTimeMinutes: 180, maxScreenTimeMinutes: 239 },
  { level: 7, name: 'General', icon: '🎯', minScreenTimeMinutes: 120, maxScreenTimeMinutes: 179 },
  { level: 8, name: 'Sigma', icon: '💎', minScreenTimeMinutes: 60, maxScreenTimeMinutes: 119 },
  { level: 9, name: 'CEO', icon: '👑', minScreenTimeMinutes: 0, maxScreenTimeMinutes: 59 }
];

export async function getTodayScreenTime() {
  const user = await base44.auth.me();
  const today = format(new Date(), 'yyyy-MM-dd');
  
  const logs = await base44.entities.ScreenTimeLog.filter({
    created_by: user.email,
    date: today
  });
  
  const totalSeconds = logs.reduce((sum, log) => sum + (log.duration_seconds || 0), 0);
  return totalSeconds / 60;
}

export async function getAverageScreenTime(days) {
  const user = await base44.auth.me();
  const startDate = format(subDays(new Date(), days - 1), 'yyyy-MM-dd');
  
  const logs = await base44.entities.ScreenTimeLog.filter({
    created_by: user.email
  });
  
  const recentLogs = logs.filter(log => log.date >= startDate);
  
  const dailyTotals = {};
  recentLogs.forEach(log => {
    if (!dailyTotals[log.date]) {
      dailyTotals[log.date] = 0;
    }
    dailyTotals[log.date] += log.duration_seconds || 0;
  });
  
  const daysWithData = Object.keys(dailyTotals).length;
  if (daysWithData === 0) return 0;
  
  const totalSeconds = Object.values(dailyTotals).reduce((sum, val) => sum + val, 0);
  return (totalSeconds / 60) / daysWithData;
}

export async function logScreenTimeSession(entityType, entityName, startTime, endTime, isSocialMedia = false) {
  const user = await base44.auth.me();
  const start = typeof startTime === 'string' ? parseISO(startTime) : startTime;
  const end = typeof endTime === 'string' ? parseISO(endTime) : endTime;
  const durationSeconds = differenceInMinutes(end, start) * 60;
  
  const activeFocusSessions = await base44.entities.FocusSession.filter({
    created_by: user.email,
    completed: false,
    early_exit: false
  });
  
  if (activeFocusSessions.length > 0) {
    const session = activeFocusSessions[0];
    const sessionStart = parseISO(session.start_time);
    const sessionEnd = addMinutes(sessionStart, session.duration_minutes);
    
    if (start >= sessionStart && end <= sessionEnd) {
      return null;
    }
  }
  
  let awarenessCount = 0;
  if (isSocialMedia) {
    const durationMinutes = durationSeconds / 60;
    awarenessCount = Math.floor(durationMinutes / 5);
  }
  
  const log = await base44.entities.ScreenTimeLog.create({
    entity_type: entityType,
    entity_name: entityName,
    start_time: start.toISOString(),
    end_time: end.toISOString(),
    duration_seconds: durationSeconds,
    date: format(start, 'yyyy-MM-dd'),
    awareness_notifications_shown: awarenessCount
  });
  
  return log;
}

export async function getOrCreateWinStreak() {
  try {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║ [getOrCreateWinStreak] START                           ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    
    const user = await base44.auth.me();
    console.log('✓ User authenticated:', user.email);
    
    let streaks = [];
    try {
      streaks = await base44.entities.WinStreak.filter({ created_by: user.email });
      console.log(`✓ Fetched ${streaks.length} streak records`);
    } catch (fetchError) {
      console.error('✗ Error fetching streak:', fetchError);
      streaks = [];
    }
    
    // SAFE: If streak exists, return it
    if (streaks && streaks.length > 0) {
      console.log('✓ Found existing streak:', streaks[0]);
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return streaks[0];
    }
    
    // SAFE: Create new streak if none exists
    console.log('⚠ No streak found, creating new one');
    try {
      const newStreak = await base44.entities.WinStreak.create({
        current_streak: 0,
        longest_streak: 0,
        total_completed_sessions: 0,
        total_failed_sessions: 0
      });
      console.log('✓ Created new streak:', newStreak);
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return newStreak;
    } catch (createError) {
      console.error('✗ Error creating streak:', createError);
      // SAFE: Return default object if creation fails
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return {
        current_streak: 0,
        longest_streak: 0,
        total_completed_sessions: 0,
        total_failed_sessions: 0
      };
    }
  } catch (error) {
    console.error('\n╔════════════════════════════════════════════════════════╗');
    console.error('║ [getOrCreateWinStreak] CRITICAL ERROR                  ║');
    console.error('╚════════════════════════════════════════════════════════╝');
    console.error('Error:', error);
    console.error('Stack:', error.stack);
    // SAFE: Always return a valid streak object
    return {
      current_streak: 0,
      longest_streak: 0,
      total_completed_sessions: 0,
      total_failed_sessions: 0
    };
  }
}

export async function incrementWinStreak() {
  const streak = await getOrCreateWinStreak();
  const newCurrent = (streak.current_streak || 0) + 1;
  const newLongest = Math.max(newCurrent, streak.longest_streak || 0);
  
  await base44.entities.WinStreak.update(streak.id, {
    current_streak: newCurrent,
    longest_streak: newLongest,
    last_session_date: format(new Date(), 'yyyy-MM-dd'),
    total_completed_sessions: (streak.total_completed_sessions || 0) + 1
  });
  
  await updateUserRank();
  await syncLeaderboardEntry();
}

export async function resetWinStreak() {
  const streak = await getOrCreateWinStreak();
  
  await base44.entities.WinStreak.update(streak.id, {
    current_streak: 0,
    total_failed_sessions: (streak.total_failed_sessions || 0) + 1
  });
  
  await updateUserRank();
  await syncLeaderboardEntry();
}

export async function startFocusSession(durationMinutes) {
  const user = await base44.auth.me();
  
  const session = await base44.entities.FocusSession.create({
    start_time: new Date().toISOString(),
    duration_minutes: durationMinutes,
    completed: false,
    early_exit: false
  });
  
  return session;
}

export async function completeFocusSession(sessionId) {
  const session = await base44.entities.FocusSession.filter({ id: sessionId });
  if (session.length === 0) throw new Error('Session not found');
  
  const sessionData = session[0];
  const startTime = parseISO(sessionData.start_time);
  const actualDuration = differenceInMinutes(new Date(), startTime);
  
  await base44.entities.FocusSession.update(sessionId, {
    end_time: new Date().toISOString(),
    completed: true,
    actual_duration_minutes: actualDuration
  });
  
  await incrementWinStreak();
  
  return { success: true, streakIncremented: true };
}

export async function exitFocusSessionEarly(sessionId) {
  const session = await base44.entities.FocusSession.filter({ id: sessionId });
  if (session.length === 0) throw new Error('Session not found');
  
  const sessionData = session[0];
  const startTime = parseISO(sessionData.start_time);
  const actualDuration = differenceInMinutes(new Date(), startTime);
  
  await base44.entities.FocusSession.update(sessionId, {
    end_time: new Date().toISOString(),
    early_exit: true,
    completed: false,
    actual_duration_minutes: actualDuration
  });
  
  await resetWinStreak();
  
  return { success: true, streakReset: true };
}

export function calculateRank(avgScreenTimeMinutes, winStreak) {
  const streakBonus = Math.min(winStreak * 10, 100);
  
  let baseTier = RANK_TIERS[0];
  for (let i = RANK_TIERS.length - 1; i >= 0; i--) {
    if (avgScreenTimeMinutes <= RANK_TIERS[i].minScreenTimeMinutes) {
      baseTier = RANK_TIERS[i];
      break;
    }
  }
  
  const totalPoints = baseTier.level * 100 + streakBonus;
  
  let finalTier = baseTier;
  for (let i = RANK_TIERS.length - 1; i >= 0; i--) {
    const tierMinPoints = RANK_TIERS[i].level * 100;
    if (totalPoints >= tierMinPoints) {
      finalTier = RANK_TIERS[i];
      break;
    }
  }
  
  const nextTier = RANK_TIERS.find(t => t.level === finalTier.level + 1);
  let progressToNext = 0;
  if (nextTier) {
    const currentTierPoints = finalTier.level * 100;
    const nextTierPoints = nextTier.level * 100;
    const progress = totalPoints - currentTierPoints;
    const required = nextTierPoints - currentTierPoints;
    progressToNext = Math.min(Math.round((progress / required) * 100), 100);
  }
  
  return {
    rank_level: finalTier.level,
    rank_name: finalTier.name,
    total_points: totalPoints,
    streak_bonus: streakBonus,
    progressToNext
  };
}

export async function updateUserRank() {
  const user = await base44.auth.me();
  const avgScreenTime = await getAverageScreenTime(7);
  const streak = await getOrCreateWinStreak();
  
  const calculated = calculateRank(avgScreenTime, streak.current_streak || 0);
  
  const existingRanks = await base44.entities.UserRank.filter({ created_by: user.email });
  
  if (existingRanks.length > 0) {
    const currentRank = existingRanks[0];
    const daysAtRank = currentRank.rank_level === calculated.rank_level 
      ? (currentRank.days_at_current_rank || 0) + 1 
      : 0;
    
    await base44.entities.UserRank.update(currentRank.id, {
      rank_level: calculated.rank_level,
      rank_name: calculated.rank_name,
      screen_time_avg_minutes: avgScreenTime,
      win_streak_bonus: calculated.streak_bonus,
      total_rank_points: calculated.total_points,
      days_at_current_rank: daysAtRank,
      previous_rank_name: currentRank.rank_name,
      last_rank_change_date: currentRank.rank_level !== calculated.rank_level 
        ? format(new Date(), 'yyyy-MM-dd')
        : currentRank.last_rank_change_date
    });
  } else {
    await base44.entities.UserRank.create({
      rank_level: calculated.rank_level,
      rank_name: calculated.rank_name,
      screen_time_avg_minutes: avgScreenTime,
      win_streak_bonus: calculated.streak_bonus,
      total_rank_points: calculated.total_points,
      days_at_current_rank: 0,
      last_rank_change_date: format(new Date(), 'yyyy-MM-dd')
    });
  }
  
  await syncLeaderboardEntry();
}

export async function getHabitsForDate(date) {
  try {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║ [getHabitsForDate] START                               ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    
    const user = await base44.auth.me();
    console.log('✓ User authenticated:', user.email);
    
    const allHabits = await base44.entities.Habit.filter({ 
      created_by: user.email,
      archived: false
    });
    
    console.log(`✓ Fetched ${allHabits.length} total habits from database`);
    
    // SAFE: If no habits exist, return empty array
    if (!allHabits || allHabits.length === 0) {
      console.log('⚠ No habits found in database, returning []');
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return [];
    }
    
    const dayOfWeek = date.getDay();
    const dateStr = format(date, 'yyyy-MM-dd');
    const dayName = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][dayOfWeek];
    
    console.log('📅 Target date:', dateStr);
    console.log('📅 Day of week (JS):', dayOfWeek, `(${dayName})`);
    console.log('\n--- Filtering habits for this specific day ---');
    
    const filtered = allHabits.filter(habit => {
      // SAFE: Check if habit object exists
      if (!habit) {
        console.log('⚠ Found null/undefined habit, skipping');
        return false;
      }
      
      console.log(`\n🔍 Checking habit: "${habit.title}"`);
      console.log(`   - is_daily: ${habit.is_daily}`);
      console.log(`   - specific_days: [${habit.specific_days || 'none'}]`);
      
      // Daily habits appear every day
      if (habit.is_daily) {
        console.log(`   ✓ MATCH - This is a daily habit`);
        return true;
      }
      
      // If not daily and no specific days defined, treat as not scheduled
      if (!habit.specific_days || !Array.isArray(habit.specific_days) || habit.specific_days.length === 0) {
        console.log(`   ✗ NO MATCH - Not daily and no specific days set`);
        return false;
      }
      
      // Check if this day is in specific_days array
      const isScheduled = habit.specific_days.includes(dayOfWeek);
      console.log(`   - specific_days includes ${dayOfWeek}? ${isScheduled}`);
      console.log(`   ${isScheduled ? '✓ MATCH' : '✗ NO MATCH'} - Habit ${isScheduled ? 'IS' : 'IS NOT'} scheduled for ${dayName}`);
      
      return isScheduled;
    });
    
    console.log('\n═══ FINAL RESULT ═══');
    console.log(`✓ ${filtered.length} habits matched for ${dateStr} (${dayName})`);
    filtered.forEach(h => console.log(`   - ${h.title}`));
    console.log('╚════════════════════════════════════════════════════════╝\n');
    
    return filtered;
  } catch (error) {
    console.error('\n╔════════════════════════════════════════════════════════╗');
    console.error('║ [getHabitsForDate] CRITICAL ERROR                      ║');
    console.error('╚════════════════════════════════════════════════════════╝');
    console.error('Error:', error);
    console.error('Stack:', error.stack);
    // SAFE: Always return empty array on error
    return [];
  }
}

export async function getHabitCompletionsForDate(date) {
  try {
    const user = await base44.auth.me();
    const dateStr = format(date, 'yyyy-MM-dd');
    
    const completions = await base44.entities.HabitCompletion.filter({
      created_by: user.email,
      date: dateStr
    });
    
    // SAFE: Return completions or empty array
    return completions || [];
  } catch (error) {
    console.error('[getHabitCompletionsForDate] ERROR:', error);
    // SAFE: Always return empty array on error
    return [];
  }
}

export async function hasUncheckedHabits(date) {
  try {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║ [hasUncheckedHabits] START                             ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    
    const user = await base44.auth.me();
    const dateStr = typeof date === 'string' ? date : format(date, 'yyyy-MM-dd');
    
    console.log(`📅 Checking date: ${dateStr}`);
    console.log(`👤 User: ${user.email}`);
    
    const pendingValidation = await base44.entities.HabitCompletion.filter({
      created_by: user.email,
      date: dateStr,
      state: 'pending_validation'
    });
    
    console.log(`✓ Found ${pendingValidation.length} completions with state 'pending_validation'`);
    
    // SAFE: Return false if no data
    if (!pendingValidation || pendingValidation.length === 0) {
      console.log(`═══ RESULT: NO pending validations for ${dateStr} ═══`);
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return false;
    }
    
    pendingValidation.forEach(c => console.log(`   - Habit ${c.habit_id} (date: ${c.date})`));
    console.log(`═══ RESULT: ${pendingValidation.length} pending validations FOUND ═══`);
    console.log('╚════════════════════════════════════════════════════════╝\n');
    return true;
  } catch (error) {
    console.error('\n╔════════════════════════════════════════════════════════╗');
    console.error('║ [hasUncheckedHabits] CRITICAL ERROR                    ║');
    console.error('╚════════════════════════════════════════════════════════╝');
    console.error('Error:', error);
    console.error('Stack:', error.stack);
    // SAFE: Return false on error (don't crash the UI)
    return false;
  }
}

export async function ensureHabitsScheduled(date) {
  try {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║ [ensureHabitsScheduled] START                          ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    
    const user = await base44.auth.me();
    const dateStr = typeof date === 'string' ? date : format(date, 'yyyy-MM-dd');
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    
    console.log(`📅 Target date: ${dateStr}`);
    console.log(`👤 User: ${user.email}`);
    
    // STEP 1: Safely get habits for this date
    console.log('\n--- STEP 1: Get habits for this date ---');
    const habits = await getHabitsForDate(dateObj);
    
    console.log(`✓ Received ${habits.length} habits from getHabitsForDate()`);
    habits.forEach(h => console.log(`   - ${h.title} (ID: ${h.id})`));
    
    // SAFE: If no habits exist, return empty data - don't crash
    if (!habits || habits.length === 0) {
      console.log(`⚠ No habits scheduled for ${dateStr}, exiting safely`);
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return { created: 0, existing: 0 };
    }
    
    // STEP 2: Safely fetch existing completions
    console.log('\n--- STEP 2: Fetch existing completions ---');
    let allCompletions = [];
    try {
      allCompletions = await base44.entities.HabitCompletion.filter({
        created_by: user.email,
        date: dateStr
      });
      console.log(`✓ Found ${allCompletions.length} existing completions`);
      allCompletions.forEach(c => console.log(`   - Completion for habit ${c.habit_id} (state: ${c.state})`));
    } catch (fetchError) {
      console.error(`✗ Error fetching completions:`, fetchError);
      allCompletions = [];
    }
    
    // STEP 3: Build completion map
    console.log('\n--- STEP 3: Build completion map ---');
    const completionMap = {};
    if (allCompletions && Array.isArray(allCompletions)) {
      allCompletions.forEach(c => {
        if (c && c.habit_id) {
          completionMap[c.habit_id] = true;
          console.log(`   ✓ Habit ${c.habit_id} already has completion`);
        }
      });
    }
    
    // STEP 4: Identify habits that need scheduling
    console.log('\n--- STEP 4: Identify habits needing completions ---');
    const habitsToSchedule = habits.filter(h => {
      const needsCompletion = h && h.id && !completionMap[h.id];
      if (needsCompletion) {
        console.log(`   → "${h.title}" needs completion record`);
      }
      return needsCompletion;
    });
    
    if (habitsToSchedule.length > 0) {
      console.log(`\n--- STEP 5: Create ${habitsToSchedule.length} completion records ---`);
      
      let created = 0;
      for (const habit of habitsToSchedule) {
        try {
          await base44.entities.HabitCompletion.create({
            habit_id: habit.id,
            date: dateStr,
            state: 'scheduled',
            completed: false
          });
          created++;
          console.log(`   ✓ Created completion for: "${habit.title}"`);
        } catch (createError) {
          console.error(`   ✗ Failed to create completion for "${habit.title}":`, createError);
          // Continue with other habits even if one fails
        }
      }
      
      console.log(`\n═══ RESULT ═══`);
      console.log(`✓ Successfully created ${created}/${habitsToSchedule.length} completions`);
      console.log(`✓ Total completions for ${dateStr}: ${allCompletions.length + created}`);
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return { created, existing: allCompletions.length };
    } else {
      console.log(`\n═══ RESULT ═══`);
      console.log(`✓ All ${habits.length} habits already have completions for ${dateStr}`);
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return { created: 0, existing: allCompletions.length };
    }
  } catch (error) {
    console.error('\n╔════════════════════════════════════════════════════════╗');
    console.error('║ [ensureHabitsScheduled] CRITICAL ERROR                 ║');
    console.error('╚════════════════════════════════════════════════════════╝');
    console.error('Error:', error);
    console.error('Stack:', error.stack);
    // SAFE: Never throw - return safe data
    return { created: 0, existing: 0, error: true };
  }
}

export async function transitionScheduledToPending(date) {
  try {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║ [transitionScheduledToPending] START                   ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    
    const user = await base44.auth.me();
    const dateStr = typeof date === 'string' ? date : format(date, 'yyyy-MM-dd');
    
    console.log(`📅 Processing date: ${dateStr}`);
    console.log(`👤 User: ${user.email}`);
    
    let scheduled = [];
    try {
      scheduled = await base44.entities.HabitCompletion.filter({
        created_by: user.email,
        date: dateStr,
        state: 'scheduled'
      });
      console.log(`✓ Found ${scheduled.length} completions with state 'scheduled'`);
    } catch (fetchError) {
      console.error('✗ Error fetching scheduled completions:', fetchError);
      scheduled = [];
    }
    
    // SAFE: If no scheduled items, return
    if (!scheduled || scheduled.length === 0) {
      console.log(`═══ RESULT: No scheduled completions for ${dateStr} ═══`);
      console.log('╚════════════════════════════════════════════════════════╝\n');
      return { transitioned: 0 };
    }
    
    scheduled.forEach(c => console.log(`   - Completion ${c.id} for habit ${c.habit_id}`));
    console.log(`\n--- Transitioning ${scheduled.length} items to 'pending_validation' ---`);
    
    let transitioned = 0;
    for (const completion of scheduled) {
      try {
        await base44.entities.HabitCompletion.update(completion.id, {
          state: 'pending_validation'
        });
        transitioned++;
        console.log(`   ✓ Transitioned completion ${completion.id}`);
      } catch (updateError) {
        console.error(`   ✗ Failed to update completion ${completion.id}:`, updateError);
        // Continue with others even if one fails
      }
    }
    
    console.log(`\n═══ RESULT: ${transitioned}/${scheduled.length} items transitioned ═══`);
    console.log('╚════════════════════════════════════════════════════════╝\n');
    return { transitioned };
  } catch (error) {
    console.error('\n╔════════════════════════════════════════════════════════╗');
    console.error('║ [transitionScheduledToPending] CRITICAL ERROR          ║');
    console.error('╚════════════════════════════════════════════════════════╝');
    console.error('Error:', error);
    console.error('Stack:', error.stack);
    // SAFE: Never throw
    return { transitioned: 0, error: true };
  }
}

export async function checkInHabit(habitId, date, completed) {
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║ [checkInHabit] START                                   ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log('📝 Parameters:', { habitId, date, completed });
  
  const user = await base44.auth.me();
  const dateStr = typeof date === 'string' ? date : format(date, 'yyyy-MM-dd');
  console.log('✓ User:', user.email);
  console.log('✓ Date string:', dateStr);
  
  const existing = await base44.entities.HabitCompletion.filter({
    created_by: user.email,
    habit_id: habitId,
    date: dateStr
  });
  
  console.log(`✓ Found ${existing.length} existing completion(s) for habit ${habitId} on ${dateStr}`);
  
  if (existing.length > 0) {
    console.log('→ Updating existing completion:', existing[0].id);
    console.log('   - Old state:', existing[0].state);
    console.log('   - New state:', completed ? 'completed' : 'missed');
    console.log('   - Completed flag:', completed);
    
    await base44.entities.HabitCompletion.update(existing[0].id, {
      state: completed ? 'completed' : 'missed',
      completed,
      checked_in_date: new Date().toISOString()
    });
    
    console.log('✓ Update successful');
    console.log('╚════════════════════════════════════════════════════════╝\n');
    return existing[0];
  } else {
    console.log('→ Creating new completion record');
    console.log('   - State:', completed ? 'completed' : 'missed');
    console.log('   - Completed flag:', completed);
    
    const completion = await base44.entities.HabitCompletion.create({
      habit_id: habitId,
      date: dateStr,
      state: completed ? 'completed' : 'missed',
      completed,
      checked_in_date: new Date().toISOString()
    });
    
    console.log('✓ Creation successful, ID:', completion.id);
    console.log('╚════════════════════════════════════════════════════════╝\n');
    return completion;
  }
}

export async function calculateWeeklyHabitScore(weekStartDate) {
  const user = await base44.auth.me();
  const weekStart = typeof weekStartDate === 'string' ? parseISO(weekStartDate) : weekStartDate;
  const weekEnd = endOfWeek(weekStart, { weekStartsOn: 1 });
  
  let totalValidated = 0;
  let totalCompleted = 0;
  
  for (let i = 0; i < 7; i++) {
    const currentDay = addDays(weekStart, i);
    const habits = await getHabitsForDate(currentDay);
    const completions = await getHabitCompletionsForDate(currentDay);
    
    const completionMap = {};
    completions.forEach(c => {
      // Ne compter que les habitudes validées (completed ou missed)
      if (c.state === 'completed' || c.state === 'missed') {
        completionMap[c.habit_id] = {
          validated: true,
          completed: c.state === 'completed' || c.completed === true
        };
      }
    });
    
    habits.forEach(habit => {
      if (completionMap[habit.id]?.validated) {
        totalValidated++;
        if (completionMap[habit.id].completed) {
          totalCompleted++;
        }
      }
    });
  }
  
  const successPercentage = totalValidated > 0 
    ? Math.round((totalCompleted / totalValidated) * 100)
    : 0;
  
  const threshold = 90;
  const thresholdMet = successPercentage >= threshold;
  
  const existingScores = await base44.entities.WeeklyHabitScore.filter({
    created_by: user.email,
    week_start_date: format(weekStart, 'yyyy-MM-dd')
  });
  
  const scoreData = {
    week_start_date: format(weekStart, 'yyyy-MM-dd'),
    week_end_date: format(weekEnd, 'yyyy-MM-dd'),
    total_expected: totalValidated,
    total_completed: totalCompleted,
    success_percentage: successPercentage,
    threshold_percentage: threshold,
    threshold_met: thresholdMet,
    calculated_date: new Date().toISOString()
  };
  
  if (existingScores.length > 0) {
    await base44.entities.WeeklyHabitScore.update(existingScores[0].id, scoreData);
    return { ...scoreData, id: existingScores[0].id };
  } else {
    const score = await base44.entities.WeeklyHabitScore.create(scoreData);
    return score;
  }
}

export async function getCurrentWeekContract() {
  const user = await base44.auth.me();
  const weekStart = startOfWeek(new Date(), { weekStartsOn: 1 });
  const weekStartStr = format(weekStart, 'yyyy-MM-dd');
  
  const contracts = await base44.entities.WeeklyContract.filter({
    created_by: user.email,
    week_start_date: weekStartStr
  });
  
  return contracts.length > 0 ? contracts[0] : null;
}

export async function createWeeklyContract(rewardText, sanctionText, thresholdPercentage = 90) {
  const user = await base44.auth.me();
  const weekStart = startOfWeek(new Date(), { weekStartsOn: 1 });
  const weekEnd = endOfWeek(weekStart, { weekStartsOn: 1 });
  
  const contract = await base44.entities.WeeklyContract.create({
    week_start_date: format(weekStart, 'yyyy-MM-dd'),
    week_end_date: format(weekEnd, 'yyyy-MM-dd'),
    reward_text: rewardText,
    sanction_text: sanctionText,
    success_threshold_percentage: thresholdPercentage,
    committed: false,
    evaluated: false,
    outcome_grade: 'pending'
  });
  
  return contract;
}

export async function commitToContract(contractId) {
  await base44.entities.WeeklyContract.update(contractId, {
    committed: true
  });
  
  const contracts = await base44.entities.WeeklyContract.filter({ id: contractId });
  return contracts[0];
}

export async function evaluateWeeklyContract(contractId) {
  const contracts = await base44.entities.WeeklyContract.filter({ id: contractId });
  if (contracts.length === 0) throw new Error('Contract not found');
  
  const contract = contracts[0];
  const weekStart = parseISO(contract.week_start_date);
  const weeklyScore = await calculateWeeklyHabitScore(weekStart);
  
  const percentage = weeklyScore.success_percentage;
  let outcomeGrade;
  
  if (percentage >= 90) {
    outcomeGrade = 'full_reward';
  } else if (percentage >= 80) {
    outcomeGrade = 'partial_reward';
  } else if (percentage >= 70) {
    outcomeGrade = 'partial_sanction';
  } else {
    outcomeGrade = 'full_sanction';
  }
  
  await base44.entities.WeeklyContract.update(contractId, {
    actual_success_percentage: percentage,
    outcome_grade: outcomeGrade,
    evaluated: true,
    evaluated_date: new Date().toISOString()
  });
  
  return { outcomeGrade, percentage };
}

export async function getTopParetoTasks(limit = 5) {
  const user = await base44.auth.me();
  
  const tasks = await base44.entities.ParetoTask.filter({
    created_by: user.email,
    completed: false
  }, 'sort_order');
  
  const highImpact = tasks.filter(t => t.impact_level === 'high');
  const mediumImpact = tasks.filter(t => t.impact_level === 'medium');
  const lowImpact = tasks.filter(t => t.impact_level === 'low');
  
  const prioritized = [...highImpact, ...mediumImpact, ...lowImpact];
  
  return prioritized.slice(0, limit);
}

export async function getNextEvent() {
  const user = await base44.auth.me();
  const now = new Date();
  
  const events = await base44.entities.CalendarEvent.filter({
    created_by: user.email
  });
  
  const upcomingEvents = events.filter(event => {
    const eventDateTime = parseISO(`${event.event_date}T${event.event_time}`);
    return eventDateTime > now;
  }).sort((a, b) => {
    const aTime = parseISO(`${a.event_date}T${a.event_time}`);
    const bTime = parseISO(`${b.event_date}T${b.event_time}`);
    return aTime - bTime;
  });
  
  return upcomingEvents.length > 0 ? upcomingEvents[0] : null;
}

export async function getUpcomingEvents(daysAhead = 30) {
  const user = await base44.auth.me();
  const now = new Date();
  const maxDate = format(addDays(now, daysAhead), 'yyyy-MM-dd');
  
  const events = await base44.entities.CalendarEvent.filter({
    created_by: user.email
  });
  
  const upcomingEvents = events.filter(event => {
    const eventDateTime = parseISO(`${event.event_date}T${event.event_time}`);
    return eventDateTime > now && event.event_date <= maxDate;
  }).sort((a, b) => {
    const aTime = parseISO(`${a.event_date}T${a.event_time}`);
    const bTime = parseISO(`${b.event_date}T${b.event_time}`);
    return aTime - bTime;
  });
  
  return upcomingEvents;
}

export async function scheduleEventNotifications(eventId) {
  const events = await base44.entities.CalendarEvent.filter({ id: eventId });
  if (events.length === 0) throw new Error('Event not found');
  
  const event = events[0];
  const eventDateTime = parseISO(`${event.event_date}T${event.event_time}`);
  
  const notification24h = new Date(eventDateTime.getTime() - 24 * 60 * 60 * 1000);
  const notification2h = new Date(eventDateTime.getTime() - 2 * 60 * 60 * 1000);
  
  await base44.entities.CalendarEvent.update(eventId, {
    notification_24h_time: notification24h.toISOString(),
    notification_2h_time: notification2h.toISOString(),
    notification_24h_sent: false,
    notification_2h_sent: false
  });
  
  return { notification24h, notification2h };
}

export async function checkAndSendEventNotifications() {
  const user = await base44.auth.me();
  const now = new Date();
  
  const events = await base44.entities.CalendarEvent.filter({
    created_by: user.email
  });
  
  for (const event of events) {
    if (event.notification_24h_time && !event.notification_24h_sent) {
      const notifTime = parseISO(event.notification_24h_time);
      if (now >= notifTime) {
        await base44.entities.CalendarEvent.update(event.id, {
          notification_24h_sent: true
        });
      }
    }
    
    if (event.notification_2h_time && !event.notification_2h_sent) {
      const notifTime = parseISO(event.notification_2h_time);
      if (now >= notifTime) {
        await base44.entities.CalendarEvent.update(event.id, {
          notification_2h_sent: true
        });
      }
    }
  }
}

export async function getApprovedApps() {
  const user = await base44.auth.me();
  
  const apps = await base44.entities.ApprovedApp.filter({
    created_by: user.email,
    approved: true
  });
  
  if (apps.length === 0) {
    const essentialApps = [
      { app_name: 'Phone', approved: true, essential: true, icon: '📞' },
      { app_name: 'Messages', approved: true, essential: true, icon: '💬' },
      { app_name: 'Calendar', approved: true, essential: true, icon: '📅' }
    ];
    
    for (const app of essentialApps) {
      await base44.entities.ApprovedApp.create(app);
    }
    
    return essentialApps;
  }
  
  return apps;
}

export async function startCEOModeSession() {
  const user = await base44.auth.me();
  
  const session = await base44.entities.CEOModeSession.create({
    start_time: new Date().toISOString(),
    approved_apps_count: 3
  });
  
  return session;
}

export async function endCEOModeSession(sessionId) {
  const sessions = await base44.entities.CEOModeSession.filter({ id: sessionId });
  if (sessions.length === 0) throw new Error('Session not found');
  
  const session = sessions[0];
  const startTime = parseISO(session.start_time);
  const duration = differenceInMinutes(new Date(), startTime);
  
  await base44.entities.CEOModeSession.update(sessionId, {
    end_time: new Date().toISOString(),
    duration_minutes: duration
  });
  
  return { duration };
}

export async function syncLeaderboardEntry() {
  const user = await base44.auth.me();
  
  const rankData = await base44.entities.UserRank.filter({ created_by: user.email });
  const streakData = await getOrCreateWinStreak();
  
  if (rankData.length === 0) return;
  
  const rank = rankData[0];
  
  const allEntries = await base44.entities.LeaderboardEntry.list();
  const sortedByRank = allEntries.sort((a, b) => b.rank_level - a.rank_level);
  const userPosition = sortedByRank.findIndex(e => e.created_by === user.email);
  const percentile = userPosition >= 0 
    ? Math.round(((sortedByRank.length - userPosition) / sortedByRank.length) * 100)
    : 50;
  
  const existingEntries = await base44.entities.LeaderboardEntry.filter({
    created_by: user.email
  });
  
  const entryData = {
    rank_level: rank.rank_level,
    rank_name: rank.rank_name,
    win_streak: streakData.current_streak || 0,
    screen_time_avg_minutes: rank.screen_time_avg_minutes,
    percentile,
    opted_in: true,
    last_sync_date: new Date().toISOString()
  };
  
  if (existingEntries.length > 0) {
    await base44.entities.LeaderboardEntry.update(existingEntries[0].id, entryData);
  } else {
    await base44.entities.LeaderboardEntry.create(entryData);
  }
}

export async function updateFriendStats(friendEmail) {
  const friends = await base44.entities.User.filter({ email: friendEmail });
  if (friends.length === 0) return null;
  
  const friendUser = friends[0];
  
  const friendRank = await base44.entities.UserRank.filter({ created_by: friendEmail });
  const friendStreak = await base44.entities.WinStreak.filter({ created_by: friendEmail });
  
  if (friendRank.length === 0) return null;
  
  const user = await base44.auth.me();
  const connections = await base44.entities.FriendConnection.filter({
    created_by: user.email,
    friend_email: friendEmail
  });
  
  if (connections.length > 0) {
    await base44.entities.FriendConnection.update(connections[0].id, {
      friend_name: friendUser.full_name,
      friend_rank_level: friendRank[0].rank_level,
      friend_rank_name: friendRank[0].rank_name,
      friend_win_streak: friendStreak.length > 0 ? friendStreak[0].current_streak : 0,
      last_updated: new Date().toISOString()
    });
  }
  
  return connections.length > 0 ? connections[0] : null;
}

export async function enforceAppBlocking(appName) {
  const user = await base44.auth.me();
  
  const blockedApps = await base44.entities.BlockedApp.filter({
    created_by: user.email,
    app_name: appName
  });
  
  if (blockedApps.length === 0) {
    return { blocked: false, timeLimit: null };
  }
  
  const blockedApp = blockedApps[0];
  
  if (blockedApp.time_limit_minutes === 0) {
    return { blocked: true, timeLimit: 0, message: 'This app is fully blocked.' };
  }
  
  const todayUsage = await getTodayScreenTime();
  
  if (todayUsage >= blockedApp.time_limit_minutes) {
    return { 
      blocked: true, 
      timeLimit: blockedApp.time_limit_minutes,
      message: `Daily limit of ${blockedApp.time_limit_minutes} minutes reached.`
    };
  }
  
  return { 
    blocked: false, 
    timeLimit: blockedApp.time_limit_minutes,
    remainingMinutes: blockedApp.time_limit_minutes - todayUsage
  };
}

export async function enforceWebsiteBlocking(urlDomain) {
  const user = await base44.auth.me();
  
  const blockedSites = await base44.entities.BlockedWebsite.filter({
    created_by: user.email,
    url_domain: urlDomain
  });
  
  if (blockedSites.length === 0) {
    return { blocked: false, timeLimit: null };
  }
  
  const blockedSite = blockedSites[0];
  
  if (blockedSite.time_limit_minutes === 0) {
    return { blocked: true, timeLimit: 0, message: 'This website is fully blocked.' };
  }
  
  const todayUsage = await getTodayScreenTime();
  
  if (todayUsage >= blockedSite.time_limit_minutes) {
    return { 
      blocked: true, 
      timeLimit: blockedSite.time_limit_minutes,
      message: `Daily limit of ${blockedSite.time_limit_minutes} minutes reached.`
    };
  }
  
  return { 
    blocked: false, 
    timeLimit: blockedSite.time_limit_minutes,
    remainingMinutes: blockedSite.time_limit_minutes - todayUsage
  };
}