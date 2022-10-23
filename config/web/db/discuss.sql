create table if not exists discuss (
  key serial primary key,
  uri text unique constraint discuss_uri check (char_length(slug) <= 256),
  slug text not null unique constraint discuss_slug_len check (char_length(slug) <= 256),
  createdtime timestamp not null default now(),
  modifiedtime timestamp not null default now(),
  title text constraint discuss_title_len check (char_length(title) <= 256)
);

create index if not exists discuss_uri on discuss (uri);
create index if not exists discuss_slug on discuss (slug);

create table if not exists comment (
  key serial primary key,
  owner int references users(key) not null,
  discuss int,
  reply int,
  distance int,
  content jsonb,
  history jsonb,
  createdtime timestamp not null default now(),
  state state not null default 'pending',
  deleted bool default false
);

create index if not exists comment_distance on comment (distance);
