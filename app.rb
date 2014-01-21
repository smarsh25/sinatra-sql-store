require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def dbname
  "storeadminsite"
end

# BONUS - refactor using this method with block.
def with_db
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  yield c
  c.close
end

get '/' do
  erb :index
end

# The Products machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  c.close
  erb :products
end

# Get the form for creating a new product
get '/products/new' do
  # Get all rows from the categories table, to provide as options in the form
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @categories = c.exec_params("SELECT id, name FROM categories;")
  c.close

  erb :new_product
end

# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (name, price, description) VALUES ($1,$2,$3)",
                  [params["name"], params["price"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]

  # IF a category was chosen...
  # create a record in product_category table to show the relation to category
  if params["category_id"] != "none"
    c.exec_params("INSERT INTO product_category (product_id, category_id) VALUES ($1,$2)",
                  [new_product_id, params["category_id"]])
  end
  
  c.close
  redirect "/products/#{new_product_id}"
end

# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the product.
  c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                [params["id"], params["name"], params["price"], params["description"]])

  # IF a category was chosen...
  # create a record in product_category table to show the relation to category

  # Delete whatever category this product had
  # (this accounts for setting to none, or changing to a new/different value)
  c.exec_params("DELETE FROM product_category WHERE product_category.product_id = $1", [params["id"]])

  # Save whatever category was selected (if it wasn't 'none')
  if params["category_id"] != "none"
    # save the
    c.exec_params("INSERT INTO product_category (product_id, category_id) VALUES ($1,$2)",
          [params["id"], params["category_id"].to_i])
  end

  c.close
  redirect "/products/#{params["id"]}"
end

get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first

  # get the products current category.
  product_category_result = c.exec_params("SELECT category_id FROM product_category WHERE product_category.product_id = $1", [params["id"]]).first
  product_category_result == nil ? @product_category = "0" : @product_category = product_category_result["category_id"]
  # binding.pry
  @categories = c.exec_params("SELECT id, name FROM categories;")  
  c.close
  erb :edit_product
end

# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.exec_params("DELETE FROM product_category WHERE product_category.product_id = $1", [params["id"]])
  c.close
  redirect '/products'
end

# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  # @product = c.exec_params("SELECT name, price, description FROM products AS p WHERE p.id = $1;", [params[:id]]).first

  @product = c.exec_params("SELECT p.name, p.price, p.description, c.name AS c_name, c.id AS c_id FROM products AS p
                              LEFT OUTER JOIN product_category AS pc on p.id = pc.product_id 
                              LEFT OUTER JOIN categories AS c on pc.category_id = c.id 
                              WHERE p.id = $1;", [params[:id]]).first

  c.close
  erb :product
end

# Get the index of categories
get '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the categories table.
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :categories
end

# Get the form for creating a new product
get '/categories/new' do
  erb :new_category
end

# POST to create a new category
post '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the categories table.
  c.exec_params("INSERT INTO categories (name) VALUES ($1)", [params["name"]])

  # Assuming you created your categories table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_category_id = c.exec_params("SELECT currval('categories_id_seq');").first["currval"]
  c.close
  # redirect "/categories/#{new_category_id}"
  redirect "/categories"
end

