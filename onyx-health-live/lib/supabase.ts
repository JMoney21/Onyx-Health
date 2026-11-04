import { createClient } from "@supabase/supabase-js";

// ONYX Health browser client.
// Supabase publishable keys are intended for client-side use; data access is protected by Auth + RLS.
const url = "https://yqwngdjjyoiczuotfbgl.supabase.co";
const key = "sb_publishable_6eLsGga6LWDSTAYmvt9JZQ_vY97Jg5P";

export const isSupabaseConfigured = true;
export const supabase = createClient(url, key, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
