-- Add `reason` column to rest_periods so each scheduled pause carries a user-supplied
-- reason. Defaults to 'flemme' when the user leaves the field blank.

ALTER TABLE public.rest_periods
  ADD COLUMN IF NOT EXISTS reason text NOT NULL DEFAULT 'flemme';

COMMENT ON COLUMN public.rest_periods.reason IS
  'User-supplied reason for the pause (defaults to "flemme" if left blank in the UI).';

-- Ask PostgREST to refresh its schema cache so the new column is queryable immediately.
NOTIFY pgrst, 'reload schema';
