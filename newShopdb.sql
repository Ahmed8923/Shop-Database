-- database: shopNew.db
CREATE TABLE IF NOT EXISTS
    "customers" (
        "custId" INTEGER PRIMARY KEY,
        "custName" TEXT NOT NULL,
        "number" INTEGER NOT NULL,
        "email" TEXT CHECK (
            email LIKE '%_@__%.__%'
            AND LENGTH(email) > 5
        ) UNIQUE NOT NULL,
        "password" TEXT NOT NULL,
        "address" TEXT NOT NULL
    );

CREATE TABLE IF NOT EXISTS
    "products" (
        "prodId" TEXT PRIMARY KEY,
        "prodName" TEXT NOT NULL,
        "categId" INTEGER,
        "description" TEXT NOT NULL,
        "cost" INTEGER NOT NULL,
        "image_url" TEXT,
        FOREIGN KEY ("categId") REFERENCES "categories" ("categId")
    );

CREATE TABLE IF NOT EXISTS
    "categories" (
        "categId" TEXT NOT NULL PRIMARY KEY,
        "categName" TEXT NOT NULL
    );

CREATE TABLE IF NOT EXISTS
    "sales" (
        "saleId" INTEGER PRIMARY KEY,
        "date" INTEGER NOT NULL,
        "prodId" INTEGER,
        "custId" INTEGER NOT NULL,
        "amount" INTEGER NOT NULL,
        FOREIGN KEY ("prodId") REFERENCES "products" ("prodId"),
        FOREIGN KEY ("custId") REFERENCES "customers" ("custId")
    );

CREATE TABLE IF NOT EXISTS
    "returns" (
        "returnId" INTEGER PRIMARY KEY,
        "saleId" INTEGER NOT NULL,
        "prodId" INTEGER NOT NULL,
        "date" INTEGER NOT NULL,
        "amount" INTEGER NOT NULL,
        FOREIGN KEY ("saleId") REFERENCES "sales" ("saleId"),
        FOREIGN KEY ("prodId") REFERENCES "products" ("prodId")
    );

CREATE TABLE IF NOT EXISTS
    "locations" (
        "locationId" INTEGER PRIMARY KEY,
        "location" TEXT NOT NULL
    );

CREATE TABLE IF NOT EXISTS
    "reviews" (
        "name" TEXT NOT NULL,
        "locationId" INTEGER NOT NULL,
        "comments" TEXT NOT NULL,
        "rating" INTEGER NOT NULL,
        FOREIGN KEY ("locationId") REFERENCES "locations" ("locationId")
    );

CREATE TABLE IF NOT EXISTS
    "messeges" (
        "name" TEXT NOT NULL,
        "messege" TEXT NOT NULL,
        "email" TEXT NOT NULL,
        FOREIGN KEY ("email") REFERENCES "customers" ("email")
    );

CREATE TABLE temp_sales( 
    "date" INTEGER,
    "sku" TEXT,
    "customer_id" TEXT,
    "quantity" INTEGER,
    "total_amount" INTEGER
); 
--- create a view for top spending customer
CREATE VIEW
    top_spending_customers AS
SELECT
    c.custId,
    c.custName,
    c.number,
    c.email,
    c.address,
    SUM(s.amount) AS total_spent
FROM
    customers c
    JOIN sales s ON c.custId = s.custId
GROUP BY
    c.custId
ORDER BY
    total_spent DESC
LIMIT
    10;

---   create view for best selling products by revenue
CREATE VIEW
    top_revenue_products AS
SELECT
    s.prodId,
    p.description,
    COUNT(s.saleId) AS total_sales,
    SUM(s.amount) AS total_revenue
FROM
    sales s
    JOIN products p ON s.prodId = p.prodId
GROUP BY
    s.prodId
ORDER BY
    total_revenue DESC
LIMIT
    5;

---   create view for low selling products by revenue
CREATE VIEW
    low_revenue_products AS
SELECT
    s.prodId,
    p.description,
    COUNT(s.saleId) AS total_sales,
    SUM(s.amount) AS total_revenue
FROM
    sales s
    JOIN products p ON s.prodId = p.prodId
GROUP BY
    s.prodId
ORDER BY
    total_revenue ASC
LIMIT
    5;

--- sales revenue by month
CREATE VIEW
    monthly_sales_revenue AS
SELECT
    strftime('%Y-%m', s.date) AS sales_month,
    SUM(s.amount) AS total_revenue
FROM
    sales s
GROUP BY
    sales_month
ORDER BY
    sales_month;

--- top membership sales in the last 30 days
--- (make sure there are some recent sales in demo data to see results)
CREATE VIEW
    recent_top_products_sales AS
SELECT
    s.prodId,
    p.description,
    COUNT(s.saleId) AS total_sales,
    SUM(s.amount) AS total_revenue
FROM
    sales s
    JOIN products p ON s.prodId = p.prodId
WHERE
    s.date >= DATE('now', '-30 days')
GROUP BY
    s.prodId
ORDER BY
    total_revenue DESC
LIMIT
    5;

--- best and worst selling month (more advanced example)
CREATE VIEW
    best_and_worst_selling_month AS
WITH
    ranked_months AS (
        SELECT
            strftime('%Y-%m', s.date) AS sales_month,
            COUNT(s.saleId) AS total_sales,
            SUM(s.amount) AS total_revenue,
            RANK() OVER (
                ORDER BY
                    SUM(s.amount) DESC
            ) AS best_rank,
            RANK() OVER (
                ORDER BY
                    SUM(s.amount) ASC
            ) AS worst_rank
        FROM
            sales s
        GROUP BY
            sales_month
    )
SELECT
    sales_month,
    total_sales,
    total_revenue,
    CASE
        WHEN best_rank = 1 THEN 'Best'
        WHEN worst_rank = 1 THEN 'Worst'
    END AS month_type
FROM
    ranked_months
WHERE
    best_rank = 1
    OR worst_rank = 1;


CREATE TRIGGER validate_password_insert
BEFORE INSERT ON customers
BEGIN
    -- Minimum length 8
    SELECT CASE
        WHEN LENGTH(NEW.password) < 8 THEN
            RAISE(ABORT, 'Password must be at least 8 characters long')
    END;

    -- At least one number
    SELECT CASE
        WHEN NEW.password NOT GLOB '*[0-9]*' THEN
            RAISE(ABORT, 'Password must contain at least one number')
    END;
END;

CREATE TRIGGER validate_passwordS_update
BEFORE UPDATE ON customers
BEGIN
    SELECT CASE
        WHEN LENGTH(NEW.password) < 8 THEN
            RAISE(ABORT, 'Password must be at least 8 characters long')
    END;

    SELECT CASE
        WHEN NEW.password NOT GLOB '*[0-9]*' THEN
            RAISE(ABORT, 'Password must contain at least one number')
    END;
END;


INSERT INTO customers (custId, custName, number, email, password, address) VALUES (200, 'Roy Willium', '355-8954', 'roy.willium@example.com', 'word9', '10 High St');