-- Fix Database Structure for SafeScales
-- This script will restore the correct Users table structure

-- First, let's check what columns currently exist
-- Run this query in your Supabase SQL editor to see current structure:
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'Users' 
ORDER BY ordinal_position;

-- If you have a 'reading_progress' column that should be 'modules', run this:
-- ALTER TABLE "Users" RENAME COLUMN "reading_progress" TO "modules";

-- If the 'modules' column doesn't exist at all, create it:
-- ALTER TABLE "Users" ADD COLUMN "modules" JSONB DEFAULT '{}';

-- If you need to create the entire Users table structure, use this:
/*
CREATE TABLE IF NOT EXISTS "Users" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "Username" TEXT NOT NULL,
    "Email" TEXT UNIQUE NOT NULL,
    "password" TEXT NOT NULL,
    "modules" JSONB DEFAULT '{}',
    "quizzes" JSONB DEFAULT '{}',
    "acquired_accessories" TEXT[] DEFAULT '{}',
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
*/

-- To check if any users have data in the wrong column, run:
-- SELECT id, "Username", "Email", "modules", "reading_progress" 
-- FROM "Users" 
-- WHERE "reading_progress" IS NOT NULL;

-- If you need to migrate data from reading_progress to modules:
-- UPDATE "Users" 
-- SET "modules" = "reading_progress" 
-- WHERE "reading_progress" IS NOT NULL AND "modules" IS NULL;

-- After migration, you can drop the reading_progress column:
-- ALTER TABLE "Users" DROP COLUMN "reading_progress";
