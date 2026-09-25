create extension if not exists pgcrypto;

create table if not exists farms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create type transaction_type as enum ('revenue', 'expense');

create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid references farms(id) on delete cascade,
  type transaction_type not null,
  transaction_date date not null default current_date,
  category text not null,
  amount numeric(14,2) not null check (amount >= 0),
  payment_method text not null default 'cash',
  description text,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_farm_date
on transactions(farm_id, transaction_date desc);
