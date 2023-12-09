\c milestone;

-- Create tables and perform other initialization tasks
CREATE TABLE fullname (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

-- Insert some initial data
INSERT INTO fullname (name) VALUES ('Ahmed Mahgoub');