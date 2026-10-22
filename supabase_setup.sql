-- Cat Talk Show dashboard permissions. Run in Supabase SQL Editor.
-- Assumes public.admin_users, videos, gallery, collaborations already exist.
-- Do not place secret keys in website HTML.

CREATE TABLE IF NOT EXISTS public.posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL DEFAULT 'post' CHECK (type IN ('post','prompt','class')),
  title text NOT NULL,
  body text NOT NULL,
  link_url text,
  created_at timestamptz DEFAULT now()
);

-- Make existing inserts work without the browser supplying UUIDs or timestamps.
ALTER TABLE public.videos ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.videos ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.gallery ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.gallery ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.collaborations ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.collaborations ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.collaborations ALTER COLUMN status SET DEFAULT 'pending';

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaborations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Admin check: users may only read their own admin membership.
DROP POLICY IF EXISTS "Cat admin self-check" ON public.admin_users;
CREATE POLICY "Cat admin self-check" ON public.admin_users FOR SELECT TO authenticated
USING (user_id = (SELECT auth.uid()));

-- Public can read published media and posts; only admin users can modify.
DROP POLICY IF EXISTS "Cat videos public read" ON public.videos;
CREATE POLICY "Cat videos public read" ON public.videos FOR SELECT TO anon,authenticated USING (true);
DROP POLICY IF EXISTS "Cat videos admin insert" ON public.videos;
CREATE POLICY "Cat videos admin insert" ON public.videos FOR INSERT TO authenticated
WITH CHECK (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Cat videos admin delete" ON public.videos;
CREATE POLICY "Cat videos admin delete" ON public.videos FOR DELETE TO authenticated
USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));

DROP POLICY IF EXISTS "Cat gallery public read" ON public.gallery;
CREATE POLICY "Cat gallery public read" ON public.gallery FOR SELECT TO anon,authenticated USING (true);
DROP POLICY IF EXISTS "Cat gallery admin insert" ON public.gallery;
CREATE POLICY "Cat gallery admin insert" ON public.gallery FOR INSERT TO authenticated
WITH CHECK (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Cat gallery admin delete" ON public.gallery;
CREATE POLICY "Cat gallery admin delete" ON public.gallery FOR DELETE TO authenticated
USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));

-- Anyone can submit a request; only admins can see or moderate requests.
DROP POLICY IF EXISTS "Cat collaborations public submit" ON public.collaborations;
CREATE POLICY "Cat collaborations public submit" ON public.collaborations FOR INSERT TO anon,authenticated
WITH CHECK (status IS NULL OR status = 'pending');
DROP POLICY IF EXISTS "Cat collaborations admin read" ON public.collaborations;
CREATE POLICY "Cat collaborations admin read" ON public.collaborations FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Cat collaborations admin update" ON public.collaborations;
CREATE POLICY "Cat collaborations admin update" ON public.collaborations FOR UPDATE TO authenticated
USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid()))))
WITH CHECK (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));

DROP POLICY IF EXISTS "Cat posts public read" ON public.posts;
CREATE POLICY "Cat posts public read" ON public.posts FOR SELECT TO anon,authenticated USING (true);
DROP POLICY IF EXISTS "Cat posts admin insert" ON public.posts;
CREATE POLICY "Cat posts admin insert" ON public.posts FOR INSERT TO authenticated
WITH CHECK (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Cat posts admin delete" ON public.posts;
CREATE POLICY "Cat posts admin delete" ON public.posts FOR DELETE TO authenticated
USING (EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));

-- Supabase Storage gallery bucket: public read; admin upload and delete.
INSERT INTO storage.buckets (id,name,public) VALUES ('gallery','gallery',true)
ON CONFLICT (id) DO UPDATE SET public=true;
DROP POLICY IF EXISTS "Cat storage admin upload" ON storage.objects;
CREATE POLICY "Cat storage admin upload" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id='gallery' AND EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Cat storage admin delete" ON storage.objects;
CREATE POLICY "Cat storage admin delete" ON storage.objects FOR DELETE TO authenticated
USING (bucket_id='gallery' AND EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Cat storage admin read" ON storage.objects;
CREATE POLICY "Cat storage admin read" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id='gallery' AND EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid())));
