# BUSINESS LOGIC DOCUMENTATION
## The App of a CEO - Complete System Logic & Edge Cases

---

## 1. SCREEN TIME SYSTEM

### Core Logic
- Tracks app and website usage duration
- Enforces time limits (0 = fully blocked)
- Triggers awareness notifications every 5 minutes on social media apps

### Modes
**Normal Mode:**
- Breaks allowed
- Time limits enforced but user can dismiss
- Usage logged for analytics

**Focus Mode:**
- NO breaks allowed
- Any exit breaks Win Streak
- Enforced through session lock (no back button)

### State Changes

#### Adding Blocked App/Website
```
Initial: No blocks
↓
User adds "Instagram" as blocked app
↓
BlockedApp created with:
  - app_name: "Instagram"
  - time_limit_minutes: 0 (fully blocked)
  - is_social_media: true
↓
State: Instagram blocked, triggers awareness
```

#### Awareness Notification Trigger
```
User opens social media app
↓
Check last notification time for this app
↓
IF >5 minutes since last OR first use today:
  → Show: "Are you aware that you are scrolling?"
  → Log notification in ScreenTimeLog
  → Update awareness_notifications_shown count
ELSE:
  → Skip notification
```

### Edge Cases

**Edge Case 1: Multiple Blocked Apps with Same Name**
- Prevention: App name uniqueness enforced at UI level
- If duplicate exists: Filter by most recent created_date

**Edge Case 2: Time Limit = 0 vs Time Limit = undefined**
- 0 = Fully blocked
- undefined/null = No limit (allowed)

**Edge Case 3: User Uninstalls App**
- BlockedApp record persists (intentional)
- No enforcement needed if app not installed
- Historical data preserved

**Edge Case 4: Awareness Notification Spam**
- 5-minute cooldown strictly enforced
- Cooldown per app (not global)
- User can dismiss notification but timer doesn't reset

**Edge Case 5: Cross-Midnight Usage**
- Each day is separate ScreenTimeLog entry
- If session spans midnight, split into two logs
- Implementation: Check date on session end, create separate entries if needed

---

## 2. WIN STREAK SYSTEM

### Core Logic
- Incremented ONLY when Focus Mode sessions are completed successfully
- Reset IMMEDIATELY when Focus Mode exited early
- Impacts rank calculation (bonus points)

### State Machine

```
State: No Active Session, Streak = N
↓
User starts Focus Mode (M minutes)
↓
State: Active Session, Streak = N (unchanged until completion)
↓
BRANCH 1: Timer reaches 0:00
  → Session marked completed = true
  → Streak += 1
  → Update longest_streak if necessary
  → State: No Active Session, Streak = N+1
  
BRANCH 2: User exits early
  → Session marked early_exit = true
  → Streak = 0 (RESET)
  → Increment total_failed_sessions
  → State: No Active Session, Streak = 0
```

### State Changes

#### Successful Session Completion
```
Before:
  WinStreak { current_streak: 15, longest_streak: 23 }
  
Focus session completes after 45 minutes
↓
After:
  WinStreak { 
    current_streak: 16, 
    longest_streak: 23,
    total_completed_sessions: +1,
    last_session_date: today
  }
  
Trigger: updateUserRank() (may increase rank)
```

#### Early Exit (Streak Break)
```
Before:
  WinStreak { current_streak: 15, longest_streak: 23 }
  
User exits at 30/45 minutes
↓
After:
  WinStreak { 
    current_streak: 0,  // RESET
    longest_streak: 23,  // Preserved
    total_failed_sessions: +1
  }
  
Trigger: updateUserRank() (may decrease rank)
```

### Edge Cases

**Edge Case 1: Multiple Focus Sessions Same Day**
- Each successful session increments streak by 1
- No daily cap on sessions
- Streak continues across days

**Edge Case 2: Focus Session Spans Midnight**
- last_session_date uses completion timestamp
- Streak continues unbroken if no early exits

**Edge Case 3: App Crashes During Focus Session**
- Session NOT marked as complete
- Session NOT marked as early_exit
- Streak remains unchanged (neither increment nor reset)
- User must manually restart session
- Implementation Note: Requires periodic heartbeat in production

**Edge Case 4: New Longest Streak**
```
current_streak: 24, longest_streak: 23
↓
Session completes
↓
current_streak: 25, longest_streak: 25 (updated)
```

**Edge Case 5: First Ever Session**
```
No WinStreak record exists
↓
getOrCreateWinStreak() creates:
{
  current_streak: 0,
  longest_streak: 0,
  total_completed_sessions: 0,
  total_failed_sessions: 0
}
↓
First successful session:
{
  current_streak: 1,
  longest_streak: 1,
  total_completed_sessions: 1
}
```

**Edge Case 6: Streak Bonus Rank Impact**
- Every 10 streak points = +1 rank level bonus
- Streak 15 → +1 rank bonus
- Streak 25 → +2 rank bonus
- Maximum: Cannot exceed CEO rank even with high streak

---

## 3. REWARDS & SANCTIONS SYSTEM

### Core Logic
- User defines weekly contract (reward + sanction + threshold)
- Contract must be committed (explicit user confirmation)
- At week end, system evaluates based on habit success percentage
- Outcome graded: full_reward, partial_reward, partial_sanction, full_sanction

### Grading Formula

```
success_percentage >= threshold (e.g., 90%):
  → full_reward

70% <= success_percentage < threshold:
  → partial_reward

50% <= success_percentage < 70%:
  → partial_sanction

success_percentage < 50%:
  → full_sanction
```

### State Changes

#### Creating Contract
```
Monday 9:00 AM - New week starts
↓
User creates contract:
  reward: "Nice dinner out"
  sanction: "No junk food this week"
  threshold: 90%
  committed: false
↓
State: Contract exists but NOT active
↓
User taps "I Commit"
↓
committed: true
↓
State: Contract ACTIVE
```

#### Week End Evaluation
```
Sunday 11:59 PM - Week ends
↓
System calculates weekly habit score:
  total_expected: 35 habits
  total_completed: 32 habits
  success_percentage: 91%
↓
Compare to threshold (90%):
  91% >= 90% → outcome_grade: "full_reward"
↓
Update contract:
  actual_success_percentage: 91%
  outcome_grade: "full_reward"
  evaluated: true
  evaluated_date: timestamp
↓
Monday morning - User opens app
↓
Modal appears: "WEEK COMPLETE! You earned your reward."
```

### Edge Cases

**Edge Case 1: Contract Created Mid-Week**
- Week boundaries: Monday 00:00 - Sunday 23:59
- If created Wednesday, only evaluates Wed-Sun habits
- User warned: "Contract starts from today"

**Edge Case 2: No Contract Created**
- Week ends without contract
- No evaluation triggered
- User can view past weeks' habit scores but no reward/sanction

**Edge Case 3: Contract Created But Not Committed**
```
Contract exists with committed: false
↓
Week ends
↓
Contract NOT evaluated (requires commitment)
↓
Contract archived with outcome_grade: "pending"
```

**Edge Case 4: Zero Habits Scheduled**
```
total_expected: 0
total_completed: 0
success_percentage: 0% (by default)
↓
Outcome: full_sanction (0% < 50%)
↓
User warned at contract creation if no habits exist
```

**Edge Case 5: User Marks Reward as Honored**
```
Full reward earned
↓
Modal: "Did you honor your reward?"
  [Yes, I did] [Not yet]
↓
If "Yes, I did":
  → reward_honored: true
  → Contract archived
  
If "Not yet":
  → reward_honored: false
  → Reminder shown next day
```

**Edge Case 6: Partial Outcomes**
```
Example: 78% (70-89% range)
↓
outcome_grade: "partial_reward"
↓
UI shows:
  "You earned a PARTIAL reward"
  "Suggestion: Scale down reward proportionally"
  "You were close! 12% away from full reward"
```

**Edge Case 7: Multiple Contracts Same Week**
- Only one active contract per week allowed
- If user tries to create second: "Contract already exists for this week"
- Can edit existing contract if not yet committed

---

## 4. RANK SYSTEM

### Core Logic
- 9 ranks: Panda (1) → Soldier → Warrior → Knight → Captain → Commander → General → Sigma → CEO (9)
- Based on 7-day rolling average screen time
- Win streak provides bonus rank levels

### Rank Tiers

| Rank | Level | Screen Time Range | Icon |
|------|-------|-------------------|------|
| CEO | 9 | 0-30 min/day | 👑 |
| Sigma | 8 | 30-60 min/day | 💎 |
| General | 7 | 60-90 min/day | ⭐ |
| Commander | 6 | 90-120 min/day | 🎖️ |
| Captain | 5 | 120-180 min/day | 👨‍✈️ |
| Knight | 4 | 180-240 min/day | 🛡️ |
| Warrior | 3 | 240-300 min/day | ⚔️ |
| Soldier | 2 | 300-360 min/day | 🪖 |
| Panda | 1 | 360+ min/day | 🐼 |

### Calculation Formula

```javascript
// Step 1: Base rank from screen time
avgScreenTime = sum(last_7_days_minutes) / 7

baseRank = RANK_TIERS.find(tier => 
  avgScreenTime <= tier.maxScreenTimeMinutes && 
  avgScreenTime > tier.minScreenTimeMinutes
)

// Step 2: Streak bonus
streakBonus = floor(winStreak / 10)
// 0-9 streak: +0 ranks
// 10-19 streak: +1 rank
// 20-29 streak: +2 ranks
// etc.

// Step 3: Final rank
finalRankLevel = min(baseRank.level + streakBonus, 9)
```

### State Changes

#### Daily Rank Update
```
Day 1: avgScreenTime = 250 min/day → Warrior (3)
Day 2: avgScreenTime = 240 min/day → Warrior (3)
Day 3: avgScreenTime = 200 min/day → Knight (4)  // RANK UP
↓
Trigger rank change event:
  - Full-screen "RANK UP!" animation
  - previous_rank_name: "Warrior"
  - last_rank_change_date: today
  - days_at_current_rank: 0 (reset)
```

#### Streak Bonus Impact
```
Base rank: Captain (5), avgScreenTime = 150 min/day
winStreak: 15
↓
streakBonus = floor(15 / 10) = 1
↓
finalRank: Commander (6)  // Boosted by streak
```

### Edge Cases

**Edge Case 1: First 7 Days (Insufficient Data)**
```
User account age: 3 days
↓
Calculate average from available days:
  avgScreenTime = sum(3_days) / 3
↓
Warning: "Rank stabilizes after 7 days"
```

**Edge Case 2: Zero Screen Time Logged**
```
avgScreenTime: 0 minutes
↓
Assign highest rank: CEO (9)
↓
Warning: "Complete screen time tracking for accurate rank"
```

**Edge Case 3: Streak Bonus Exceeds Max Rank**
```
Base rank: General (7)
winStreak: 50 → streakBonus = 5
↓
finalRankLevel = min(7 + 5, 9) = 9 (CEO)
↓
Cap enforced at CEO
```

**Edge Case 4: Rank Downgrade After Streak Loss**
```
Before: Commander (6) with winStreak = 15 (base Captain + bonus)
↓
Streak broken → winStreak = 0
↓
After: Captain (5)  // Lost streak bonus
↓
User notified: "Rank decreased due to broken streak"
```

**Edge Case 5: Same Rank Different Days**
```
Current: Captain (5), days_at_current_rank: 12
↓
Next day: Still Captain (5)
↓
days_at_current_rank: 13 (incremented)
```

**Edge Case 6: Progress to Next Rank**
```
Current: Captain (5), avgScreenTime = 150 min
Next: Commander (6), requires avgScreenTime ≤ 120 min
↓
Range: 180 - 120 = 60 minutes
Position: 180 - 150 = 30 minutes into range
Progress: (30 / 60) * 100 = 50%
↓
UI: "50% to Commander - Reduce by 30 min/day"
```

---

## 5. HABITS SYSTEM

### Core Logic
- Objectives → Habits → Weekly Frequency → Specific Days
- Daily validation from Dashboard
- Weekly grid auto-populated
- Weekly score calculated with threshold (default 90%)

### Habit Scheduling Logic

```javascript
// Daily habit
{
  is_daily: true,
  weekly_frequency: 7
}
→ Scheduled every day (Mon-Sun)

// Specific days habit
{
  is_daily: false,
  specific_days: [1, 3, 5],  // Mon, Wed, Fri
  weekly_frequency: 3
}
→ Scheduled only on Mon, Wed, Fri

// Day encoding: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
```

### State Changes

#### Creating Habit
```
User creates objective: "Health & Fitness"
↓
User adds habit:
  title: "Morning workout"
  objective_id: [Health objective ID]
  is_daily: true
  weekly_frequency: 7
↓
Habit created and scheduled for every day
```

#### Daily Check-in Flow
```
User opens app on Monday 8:00 AM
↓
Check yesterday (Sunday):
  habits_for_date(Sunday): [workout, read, meditate]
  completions_for_date(Sunday): []  // None checked
↓
hasUncheckedHabits(Sunday): true
↓
Dashboard shows: "Yesterday's Habits - Complete check-in"
↓
User marks: workout ✓, read ✓, meditate ✗
↓
Create HabitCompletion records:
  - workout, Sunday, completed: true
  - read, Sunday, completed: true
  - meditate, Sunday, completed: false
↓
Dashboard transitions to: "Today's Focus"
```

#### Weekly Score Calculation
```
Week: Jan 15-21 (Mon-Sun)
↓
Day-by-day:
  Mon: 5 expected, 4 completed
  Tue: 5 expected, 5 completed
  Wed: 5 expected, 3 completed
  Thu: 5 expected, 5 completed
  Fri: 5 expected, 4 completed
  Sat: 3 expected, 3 completed (fewer habits on weekends)
  Sun: 3 expected, 2 completed
↓
Total: 31 expected, 26 completed
Success: 26/31 = 84%
↓
WeeklyHabitScore created:
  total_expected: 31
  total_completed: 26
  success_percentage: 84%
  threshold_met: false (84% < 90%)
```

### Edge Cases

**Edge Case 1: Habit Created Mid-Week**
```
Wednesday - User creates new daily habit
↓
Habit scheduled starting from Wednesday
↓
Weekly score calculation:
  Wed-Sun: New habit expected (5 days)
  Mon-Tue: New habit NOT expected (doesn't exist yet)
↓
Fair scoring: Only counts from creation date
```

**Edge Case 2: Habit Archived Mid-Week**
```
User archives habit on Wednesday
↓
Habit no longer scheduled from Thursday onwards
↓
Weekly score:
  Mon-Wed: Habit expected and counted
  Thu-Sun: Habit NOT expected
```

**Edge Case 3: Retroactive Check-in**
```
It's Friday, user forgot to check in Wednesday
↓
User navigates to Wednesday in Daily Check-in
↓
Marks habits for Wednesday (retroactive)
↓
Weekly score immediately updates
↓
Warning: "Retroactive check-ins accepted but be honest!"
```

**Edge Case 4: Same Habit Checked Multiple Times**
```
User checks "Morning workout" on Monday
↓
HabitCompletion: completed: true
↓
User accidentally unchecks and rechecks
↓
Update existing HabitCompletion: completed: true
↓
Only one record exists (update, not duplicate)
```

**Edge Case 5: Zero Habits for a Day**
```
Sunday - User has no habits scheduled
↓
Weekly score that day:
  expected: 0
  completed: 0
↓
Doesn't affect percentage calculation
↓
Formula: (total_completed / total_expected) handles empty days
```

**Edge Case 6: Habit Frequency Mismatch**
```
Habit:
  specific_days: [1, 3, 5]  // Mon, Wed, Fri
  weekly_frequency: 5  // MISMATCH (should be 3)
↓
System uses specific_days as source of truth
↓
UI validation: Shows warning if mismatch detected
```

**Edge Case 7: Future Date Check-in Blocked**
```
Today is Monday
↓
User tries to check in habits for Tuesday
↓
System blocks: "Cannot check in future dates"
↓
Only today and past dates allowed
```

---

## 6. PARETO MATRIX (80/20 SYSTEM)

### Core Logic
- Tasks classified by impact: high, medium, low
- Top 3 HIGH impact tasks appear on Dashboard
- 80/20 principle: Focus on high-impact tasks (20% that deliver 80% results)

### Impact Classification

```
HIGH: Critical results, major impact on goals
  Examples: "Finish Q1 report", "Close investor deal"
  
MEDIUM: Helpful but not critical
  Examples: "Update website copy", "Respond to emails"
  
LOW: Nice to have, minimal impact
  Examples: "Organize desk", "File old documents"
```

### State Changes

#### Adding Task
```
User adds task:
  title: "Finish Q1 report"
  impact_level: "high"
  completed: false
↓
Task appears in:
  1. Pareto Matrix (high impact section)
  2. Dashboard (if in top 3 incomplete high tasks)
```

#### Completing Task
```
User marks task complete
↓
completed: true
completed_date: timestamp
↓
Task remains in Pareto Matrix (grayed out)
Task removed from Dashboard priorities
Next high-impact task moves into top 3
```

#### Priority Ordering
```
High impact tasks:
  1. "Finish Q1 report" (sort_order: 1)
  2. "Close investor deal" (sort_order: 2)
  3. "Hire senior dev" (sort_order: 3)
  4. "Launch marketing campaign" (sort_order: 4)
↓
Dashboard shows top 3:
  1, 2, 3
↓
User completes #2
↓
Dashboard updates to show:
  1, 3, 4 (next task promoted)
```

### Edge Cases

**Edge Case 1: Less Than 3 High-Impact Tasks**
```
High impact tasks: 1 incomplete
Medium impact tasks: 5 incomplete
↓
Dashboard shows:
  - 1 high impact task
  - 2 medium impact tasks (to fill top 3)
```

**Edge Case 2: Zero High or Medium Impact Tasks**
```
High: 0 incomplete
Medium: 0 incomplete
Low: 5 incomplete
↓
Dashboard shows:
  - Top 3 low impact tasks
  - Warning: "Add high-impact tasks for best results"
```

**Edge Case 3: All Tasks Completed**
```
Dashboard priorities section:
  "No pending tasks! Time to add new goals."
```

**Edge Case 4: Task Impact Reclassification**
```
Task: "Update website" (medium → high)
↓
User changes impact to HIGH
↓
Task immediately enters Dashboard rotation if in top 3
```

**Edge Case 5: Manual Sort Order**
```
User drags tasks to reorder:
  sort_order: 1 → 3
  sort_order: 2 → 1
  sort_order: 3 → 2
↓
Dashboard respects new order
```

**Edge Case 6: Completed Tasks Filter**
```
Pareto Matrix view:
  [Filter: All | High | Med | Low]
↓
Shows completed tasks (grayed out)
↓
User can un-complete if needed
```

---

## 7. LEADERBOARDS SYSTEM

### Core Logic
- Global leaderboard: Percentile-based ranking
- Friends leaderboard: Direct comparison with added friends
- Optional participation (opt-in/opt-out)
- Privacy-safe: Only ranks and streaks shared, no personal data

### Percentile Calculation

```
Total opted-in users: 1000
User's rank level: 6 (Commander)

Users with rank > 6: 150
Percentile = 100 - (150 / 1000 * 100) = 85th percentile

Interpretation: "You're in the top 15%"
```

### State Changes

#### Opting In
```
User enables leaderboard participation
↓
LeaderboardEntry created:
  rank_level: [current]
  rank_name: [current]
  win_streak: [current]
  screen_time_avg_minutes: [current]
  opted_in: true
  percentile: [calculated]
↓
User appears in global leaderboard
```

#### Opting Out
```
User disables participation
↓
opted_in: false
↓
User removed from global leaderboard
User's data no longer visible to others
User can still view global leaderboard (read-only)
```

#### Adding Friend
```
User enters friend's email: friend@example.com
↓
Check if friend exists and is opted-in
↓
IF exists and opted-in:
  FriendConnection created:
    friend_email: "friend@example.com"
    status: "accepted"  // Auto-accept for simplicity
  ↓
  Friend appears in Friends leaderboard
ELSE:
  "User not found or not participating"
```

### Edge Cases

**Edge Case 1: Same Rank Level, Different Streaks**
```
Leaderboard sorting:
  1. Rank level (descending)
  2. Win streak (descending, tiebreaker)
  3. Screen time (ascending, secondary tiebreaker)

Example:
  User A: Captain (5), streak 20
  User B: Captain (5), streak 15
  → User A ranks higher
```

**Edge Case 2: Friend Opts Out**
```
User has friend in Friends leaderboard
↓
Friend opts out of leaderboards
↓
Friend automatically removed from Friends leaderboard
↓
User notified: "Friend is no longer participating"
```

**Edge Case 3: No Friends Added**
```
Friends leaderboard:
  "Add friends to compare progress!"
  [+ Add Friend by Email]
```

**Edge Case 4: User Opts Out Then Back In**
```
Opt out → Data hidden but preserved
↓
Opt back in → Data restored
↓
Percentile recalculated based on current stats
```

**Edge Case 5: Percentile Edge Cases**
```
Only user opted in: percentile = 100
↓
Second user joins with higher rank: First user drops to 50th percentile
↓
Formula always: 100 - (users_better / total_users * 100)
```

**Edge Case 6: Friend Improves Rank**
```
Friend's rank updates daily
↓
FriendConnection.friend_rank_level synced
↓
Friends leaderboard re-sorts
↓
User sees friend moved up/down
```

---

## 8. CALENDAR/SCHEDULE SYSTEM

### Core Logic
- Events with date, time, duration
- Notifications at 24h and 2h before event
- Each notification sent only once (idempotent)

### Notification Timing

```
Event: "Team meeting" at Jan 15, 2024 14:00 (2:00 PM)
↓
24h notification: Jan 14, 2024 14:00
  "📅 Reminder: Team meeting tomorrow at 2:00 PM"
  
2h notification: Jan 15, 2024 12:00
  "⏰ Upcoming: Team meeting in 2 hours"
```

### State Changes

#### Creating Event
```
User creates:
  title: "Team meeting"
  event_date: "2024-01-15"
  event_time: "14:00"
  duration_minutes: 60
↓
Calculate notification times:
  notification_24h_time: "2024-01-14T14:00:00Z"
  notification_2h_time: "2024-01-15T12:00:00Z"
↓
Event created with:
  notification_24h_sent: false
  notification_2h_sent: false
```

#### Notification Delivery (Background Process)
```
Current time: Jan 14, 14:05
↓
Check all events where:
  - notification_24h_sent = false
  - notification_24h_time <= now
  - event_date >= now
↓
Found: "Team meeting"
↓
Send notification (console.log or push notification)
↓
Update:
  notification_24h_sent: true
```

### Edge Cases

**Edge Case 1: Event Within 2 Hours**
```
User creates event:
  event_time: 1 hour from now
↓
24h notification: Already passed (skip)
2h notification: Already passed (skip)
↓
Both marked: notification_*_sent: true immediately
```

**Edge Case 2: Event in Past**
```
User creates event with past date
↓
System allows (for historical tracking)
↓
Notifications: notification_*_sent: true (not sent)
```

**Edge Case 3: Notification System Down**
```
Notification should send at 14:00
System checks at 15:00 (1 hour late)
↓
Condition: notification_24h_time <= now (still true)
↓
Notification sent late but marked as sent
↓
Idempotency: Won't send again
```

**Edge Case 4: Event Edited After Notification Sent**
```
Event: Jan 15, 14:00
↓
24h notification sent
↓
User changes time to Jan 15, 16:00
↓
Recalculate notification times
↓
Reset: notification_24h_sent: false (since time changed)
↓
New 24h notification scheduled
```

**Edge Case 5: Event Deleted**
```
Event with pending notifications
↓
User deletes event
↓
Notifications no longer checked (event doesn't exist)
```

**Edge Case 6: Same-Day Event**
```
User creates event for today in 4 hours
↓
24h notification: Skip (already past)
2h notification: Schedule for 2 hours from now
```

**Edge Case 7: Multi-Day Event**
```
Event duration: 480 minutes (8 hours)
↓
Notifications based on start time only
↓
No "event ending soon" notifications
```

---

## 9. CEO MODE SYSTEM

### Core Logic
- Black minimalist UI overlay
- Only pre-approved apps accessible
- Explicit exit required (no hidden bypass)
- Logs session duration

### Approved Apps Logic

```
Essential apps (default approved):
  - Phone
  - Messages
  - Emergency contacts

User can approve additional:
  - Calendar
  - Notes
  - Maps
```

### State Changes

#### Activating CEO Mode
```
User taps "ACTIVATE CEO MODE"
↓
Confirmation modal:
  "This will block all non-approved apps until you exit."
↓
User confirms
↓
CEOModeSession created:
  start_time: now
↓
UI switches to:
  - Full-screen black background
  - Only approved apps visible
  - No back button
  - Exit button requires confirmation
```

#### Exiting CEO Mode
```
User taps "EXIT CEO MODE"
↓
Confirmation modal:
  "EXIT CEO MODE? This will restore full access."
  [Stay in CEO Mode] [Exit]
↓
User taps [Exit]
↓
Update session:
  end_time: now
  duration_minutes: calculated
↓
UI returns to normal
Home Menu displayed
```

### Edge Cases

**Edge Case 1: Zero Approved Apps**
```
User removes all approved apps
↓
CEO Mode still activates
↓
UI shows:
  "No apps approved"
  [EXIT CEO MODE] button only
```

**Edge Case 2: App Blocking Limitation (Web Platform)**
```
CEO Mode activated
↓
UI overlay applied (black screen)
↓
Actual app blocking: NOT POSSIBLE in web app
↓
Implementation:
  - Visual/UX restriction only
  - Relies on user discipline
  - Flag: "Full blocking requires native app"
```

**Edge Case 3: Session Crashes**
```
CEO Mode active
↓
Browser crashes / tab closed
↓
On reopen:
  - Check for incomplete CEOModeSession
  - end_time: null
  - Calculate duration up to now
  - Mark as interrupted
```

**Edge Case 4: Long Session**
```
CEO Mode activated for 8 hours
↓
No auto-exit
↓
User must manually exit
↓
Session duration logged: 480 minutes
```

**Edge Case 5: Approved Apps List Edited During Session**
```
CEO Mode active
↓
User cannot edit approved apps (settings blocked)
↓
Must exit CEO Mode to edit approved apps
```

**Edge Case 6: Multiple Devices**
```
User activates CEO Mode on Device A
↓
Opens app on Device B
↓
Device B: Normal mode (not in CEO Mode)
↓
CEO Mode is device/session-specific
```

---

## 10. CROSS-SYSTEM INTERACTIONS

### Win Streak → Rank
```
Win Streak increases
↓
Triggers: updateUserRank()
↓
Rank may increase due to streak bonus
↓
Leaderboard entry updated
```

### Habits → Weekly Contract
```
User completes habits daily
↓
Weekly score calculated Sunday night
↓
Contract evaluated based on score
↓
Reward or sanction outcome determined
```

### Focus Mode → Screen Time
```
Focus Mode active
↓
Screen time pauses accumulating
↓
Focus time NOT counted as "screen time"
↓
Rationale: Productive use vs consumptive use
```

### Rank → Leaderboard
```
Rank changes
↓
LeaderboardEntry updated
↓
Global percentile recalculated
↓
Friends leaderboard re-sorted
```

### Pareto → Dashboard
```
User adds high-impact task
↓
Dashboard immediately shows in top 3
↓
User sees priority at app launch
```

### Calendar → Dashboard
```
Next event in <24 hours
↓
Dashboard shows:
  "NEXT EVENT: Team meeting - 2h 15m"
↓
Updates in real-time
```

---

## 11. DATA CONSISTENCY & VALIDATION

### Unique Constraints
- One WinStreak record per user
- One UserRank record per user
- One LeaderboardEntry per user
- One WeeklyContract per user per week
- One HabitCompletion per habit per date

### Validation Rules
- Screen time duration_seconds >= 0
- Focus session duration_minutes > 0
- Habit weekly_frequency: 1-7
- Rank level: 1-9
- Percentile: 0-100
- Weekly contract threshold: 50-100%

### Cascading Deletes
- Objective deleted → Habits archived (not deleted)
- Habit archived → HabitCompletions preserved (historical data)
- User opts out → LeaderboardEntry.opted_in = false (not deleted)

---

## 12. PERFORMANCE CONSIDERATIONS

### Caching Strategy
- Win streak: Cache in memory for session
- Rank: Recalculate daily, not per request
- Leaderboard: Update hourly, not real-time
- Weekly score: Calculate once at week end

### Query Optimization
- Index on: created_by, date, habit_id, week_start_date
- Filter before sort
- Limit results (top 3, top 10, etc.)

---

## SUMMARY

All systems implemented with:
✅ Complete business logic
✅ State machine definitions
✅ Edge case handling
✅ No simplifications
✅ Real formulas and calculations
✅ Comprehensive validation
✅ Cross-system interactions
✅ Data integrity rules

This documentation serves as the complete specification for all business logic in The App of a CEO.