-- migrate:up
-- Create blogs table
create table blogs (
    id uuid not null primary key,
    profile_id uuid not null,
    created_at timestamp with time zone,
    title text not null,
    content text not null,
    image_url text,
    tags text [],
    foreign key (profile_id) references public.profiles(id)
);

-- Enable Row Level Security (RLS) if not already enabled
alter table blogs enable row level security;

-- Drop existing policies for blogs table if they exist
drop policy if exists "Public blogs are viewable by everyone." on blogs;
drop policy if exists "Users can insert their own blog." on blogs;
drop policy if exists "Users can update own blog." on blogs;

-- Policies for blogs table
create policy "Public blogs are viewable by everyone." on blogs
  for select using (true);

create policy "Users can insert their own blog." on blogs
  for insert with check ((select auth.uid()) = profile_id);

create policy "Users can update own blog." on blogs
  for update using ((select auth.uid()) = profile_id);

-- Set up Storage if not already created
insert into storage.buckets (id, name)
  values ('blog_images', 'blog_images')
  on conflict (id) do nothing;

-- Enable RLS on storage.objects if not already enabled
alter table storage.objects enable row level security;

-- Drop existing policies for storage.objects if they exist
drop policy if exists "Blog images are publicly accessible." on storage.objects;
drop policy if exists "Anyone can upload a blog_image." on storage.objects;
drop policy if exists "Anyone can update their own blog_image." on storage.objects;

-- Update existing policies to restrict access to authenticated users only
create policy "Authenticated users can access blog images" on storage.objects
  for select using (auth.role() = 'authenticated' and bucket_id = 'blog_images');

create policy "Authenticated users can upload blog images" on storage.objects
  for insert with check (auth.role() = 'authenticated' and bucket_id = 'blog_images');

create policy "Authenticated users can update their own blog images" on storage.objects
  for update using (auth.uid() = owner and bucket_id = 'blog_images')
  with check (auth.role() = 'authenticated' and bucket_id = 'blog_images');

-- Additional policy to allow authenticated users to delete their own blog images
create policy "Authenticated users can delete their own blog images" on storage.objects
  for delete using (auth.uid() = owner and bucket_id = 'blog_images');

-- migrate:down