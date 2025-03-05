-- Create tables
CREATE TABLE IF NOT EXISTS equipment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT,
    phone TEXT,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES customers(id),
    customer_email TEXT NOT NULL,
    items JSONB NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS contact_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_email TEXT NOT NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create RLS policies
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;

-- Equipment policies
CREATE POLICY "Enable read access for all users" ON equipment FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON equipment FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users only" ON equipment FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users only" ON equipment FOR DELETE USING (auth.role() = 'authenticated');

-- Customers policies
CREATE POLICY "Enable read access for authenticated users" ON customers FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON customers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON customers FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON customers FOR DELETE USING (auth.role() = 'authenticated');

-- Orders policies
CREATE POLICY "Enable read access for authenticated users" ON orders FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for all users" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users" ON orders FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON orders FOR DELETE USING (auth.role() = 'authenticated');

-- Contact submissions policies
CREATE POLICY "Enable read access for authenticated users" ON contact_submissions FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for all users" ON contact_submissions FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users" ON contact_submissions FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON contact_submissions FOR DELETE USING (auth.role() = 'authenticated');

-- Create storage bucket for product images
INSERT INTO storage.buckets (id, name, public) VALUES ('admin', 'admin', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
CREATE POLICY "Give public access to admin bucket" ON storage.objects FOR SELECT
USING (bucket_id = 'admin');

CREATE POLICY "Enable authenticated uploads to admin bucket" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'admin' AND auth.role() = 'authenticated');

CREATE POLICY "Enable authenticated updates to admin bucket" ON storage.objects FOR UPDATE
USING (bucket_id = 'admin' AND auth.role() = 'authenticated');

CREATE POLICY "Enable authenticated deletes to admin bucket" ON storage.objects FOR DELETE
USING (bucket_id = 'admin' AND auth.role() = 'authenticated');
