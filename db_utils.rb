require 'pry'
require 'pg'

def dbname
  "storeadminsite"
end

# GIVEN: storeadminsite has been created via psql.

def create_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end


def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec "DROP TABLE products;"
  c.close
end

def seed_products_table
  products = [["Laser", "325", "Good for lasering."],
              ["Shoe", "23.4", "Just the left one."],
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],
              ["Whiteboard", "125", "Can be written on."],
              ["Chalkboard", "100", "Can be written on.  Smells like education."],
              ["Podium", "70", "All the pieces swivel separately."],
              ["Bike", "150", "Good for biking from place to place."],
              ["Kettle", "39.99", "Good for boiling."],
              ["Toaster", "20.00", "Toasts your enemies!"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  products.each do |p|
    c.exec_params("INSERT INTO products (name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end
