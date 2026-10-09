ALTER TABLE daily_verses ADD COLUMN translation TEXT DEFAULT 'KJV';
UPDATE daily_verses SET translation = 'KJV' WHERE translation IS NULL;
