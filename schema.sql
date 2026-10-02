-- Supabase > SQL Editor mein paste karke Run karo (naye tables, purane tables ko nahi chhuta)
create table if not exists lms_profiles(id uuid primary key references auth.users on delete cascade, email text, name text, role text default 'student');
create table if not exists lms_courses(id bigint generated always as identity primary key, title text not null, description text, price int default 0, created_at timestamptz default now());
create table if not exists lms_lessons(id bigint generated always as identity primary key, course_id bigint references lms_courses on delete cascade, title text not null, youtube_id text not null, position int default 0);
create table if not exists lms_enrollments(id bigint generated always as identity primary key, user_id uuid references auth.users on delete cascade, email text, course_id bigint references lms_courses on delete cascade, utr text, status text default 'pending', created_at timestamptz default now(), unique(user_id,course_id));

create or replace function lms_is_admin() returns boolean language sql security definer stable as
$$ select exists(select 1 from lms_profiles where id=auth.uid() and role='admin') $$;

alter table lms_profiles enable row level security;
alter table lms_courses enable row level security;
alter table lms_lessons enable row level security;
alter table lms_enrollments enable row level security;

create policy p_sel on lms_profiles for select using (id=auth.uid() or lms_is_admin());
create policy p_ins on lms_profiles for insert with check (id=auth.uid() and role='student');
create policy c_sel on lms_courses for select using (true);
create policy c_all on lms_courses for all using (lms_is_admin()) with check (lms_is_admin());
create policy l_sel on lms_lessons for select using (lms_is_admin() or exists(select 1 from lms_enrollments e where e.course_id=lms_lessons.course_id and e.user_id=auth.uid() and e.status='approved'));
create policy l_all on lms_lessons for all using (lms_is_admin()) with check (lms_is_admin());
create policy e_sel on lms_enrollments for select using (user_id=auth.uid() or lms_is_admin());
create policy e_ins on lms_enrollments for insert with check (user_id=auth.uid() and status='pending');
create policy e_upd on lms_enrollments for update using (lms_is_admin());

-- Pehle website par signup karo, phir apni email yahan likh kar ek baar Run karo (aap admin ban jaoge):
-- update lms_profiles set role='admin' where email='AAPKI_EMAIL@gmail.com';
