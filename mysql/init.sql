use sqlboiler_upsert_all;

CREATE TABLE users (
  id varchar(255) not null,
  name varchar(255) not null,
  created_at datetime not null default current_timestamp,
  updated_at datetime not null default current_timestamp on update current_timestamp,
  primary key (id)
);

INSERT INTO users (id, name, created_at, updated_at) VALUES
('1', 'user1', NOW(), NOW()),
('2', 'user2', NOW(), NOW()),
('3', 'user3', NOW(), NOW()),
('4', 'user4', NOW(), NOW()),
('5', 'user5', NOW(), NOW());
