-- Run once on an existing Maxlond installation before creating accountant users.
ALTER TABLE users
    MODIFY role ENUM('admin','engineer','accountant') NOT NULL DEFAULT 'engineer';