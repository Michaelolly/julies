-- Create storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('admin', 'admin', true)
ON CONFLICT (id) DO NOTHING;

-- Create equipment table if it doesn't exist
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

-- Create customers table if it doesn't exist
CREATE TABLE IF NOT EXISTS customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create orders table if it doesn't exist
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES customers(id),
    status TEXT NOT NULL DEFAULT 'pending',
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    items JSONB NOT NULL DEFAULT '[]',
    rental_start TIMESTAMP WITH TIME ZONE,
    rental_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create analytics_data table if it doesn't exist
CREATE TABLE IF NOT EXISTS analytics_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL,
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    active_rentals INTEGER DEFAULT 0,
    new_customers INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Enable RLS on all tables
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_data ENABLE ROW LEVEL SECURITY;

-- Equipment policies
CREATE POLICY "Enable read access for all users" ON equipment
    FOR SELECT USING (true);

CREATE POLICY "Enable write access for authenticated users" ON equipment
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON equipment
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON equipment
    FOR DELETE USING (auth.role() = 'authenticated');

-- Customers policies
CREATE POLICY "Enable read access for authenticated users" ON customers
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable write access for authenticated users" ON customers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON customers
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Orders policies
CREATE POLICY "Enable read access for authenticated users" ON orders
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable write access for authenticated users" ON orders
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON orders
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Analytics policies
CREATE POLICY "Enable read access for authenticated users" ON analytics_data
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable write access for authenticated users" ON analytics_data
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON analytics_data
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Storage policies
CREATE POLICY "Give public access to admin bucket" ON storage.objects
    FOR SELECT USING (bucket_id = 'admin');

CREATE POLICY "Enable authenticated uploads to admin bucket" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'admin' AND auth.role() = 'authenticated');

CREATE POLICY "Enable authenticated updates to admin bucket" ON storage.objects
    FOR UPDATE USING (bucket_id = 'admin' AND auth.role() = 'authenticated');

CREATE POLICY "Enable authenticated deletes to admin bucket" ON storage.objects
    FOR DELETE USING (bucket_id = 'admin' AND auth.role() = 'authenticated');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_date ON analytics_data(date);

-- Create function to update customer stats
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE customers
        SET 
            total_orders = total_orders + 1,
            total_spent = total_spent + NEW.total_amount
        WHERE id = NEW.customer_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE customers
        SET 
            total_orders = total_orders - 1,
            total_spent = total_spent - OLD.total_amount
        WHERE id = OLD.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating customer stats
DROP TRIGGER IF EXISTS update_customer_stats_trigger ON orders;
CREATE TRIGGER update_customer_stats_trigger
    AFTER INSERT OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_stats();
