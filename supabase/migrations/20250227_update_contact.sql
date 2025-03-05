-- Update contact_submissions table if needed
DO $$ 
BEGIN
    -- Add status column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'contact_submissions' 
        AND column_name = 'status'
    ) THEN
        ALTER TABLE contact_submissions ADD COLUMN status TEXT NOT NULL DEFAULT 'new';
    END IF;

    -- Add subject column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'contact_submissions' 
        AND column_name = 'subject'
    ) THEN
        ALTER TABLE contact_submissions ADD COLUMN subject TEXT NOT NULL DEFAULT '';
    END IF;

    -- Add customer_email column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'contact_submissions' 
        AND column_name = 'customer_email'
    ) THEN
        ALTER TABLE contact_submissions ADD COLUMN customer_email TEXT NOT NULL DEFAULT '';
    END IF;

    -- Add message column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'contact_submissions' 
        AND column_name = 'message'
    ) THEN
        ALTER TABLE contact_submissions ADD COLUMN message TEXT NOT NULL DEFAULT '';
    END IF;

    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'contact_submissions' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE contact_submissions ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW());
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'contact_submissions' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE contact_submissions ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW());
    END IF;
END $$;

-- Update or create RLS policies
ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON contact_submissions;
DROP POLICY IF EXISTS "Enable insert for all users" ON contact_submissions;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON contact_submissions;

-- Create new policies
CREATE POLICY "Enable read access for authenticated users" 
ON contact_submissions FOR SELECT 
USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for all users" 
ON contact_submissions FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users" 
ON contact_submissions FOR UPDATE 
USING (auth.role() = 'authenticated');
