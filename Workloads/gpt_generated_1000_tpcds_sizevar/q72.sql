WITH sampled_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_paid,
        s.s_store_name,
        i.i_category,
        i.i_product_name,
        ca.ca_city,
        ca.ca_zip
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
      AND regexp_like(i.i_product_name, 'Premium')
      AND ca.ca_city LIKE 'A%'
),
returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_amt,
        s.s_store_name,
        i.i_category,
        i.i_product_name,
        ca.ca_city,
        ca.ca_zip
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
)
SELECT
    COALESCE(sales.s_store_name, returns.s_store_name) AS store_name,
    COALESCE(sales.i_category, returns.i_category) AS product_category,
    regexp_extract(COALESCE(sales.i_product_name, returns.i_product_name), '(\\w+)', 1) AS product_first_word,
    COUNT(DISTINCT sales.ss_ticket_number) AS sales_transactions,
    SUM(COALESCE(sales.ss_net_paid, 0)) AS total_sales_net_paid,
    SUM(COALESCE(returns.sr_return_amt, 0)) AS total_return_amount,
    CONCAT('City_', COALESCE(sales.ca_city, returns.ca_city)) AS city_label,
    SUBSTRING(COALESCE(sales.ca_zip, returns.ca_zip), 1, 3) AS zip_prefix
FROM sampled_sales sales
FULL OUTER JOIN returns
    ON sales.ss_ticket_number = returns.sr_ticket_number
   AND sales.ss_item_sk = returns.sr_item_sk
GROUP BY
    COALESCE(sales.s_store_name, returns.s_store_name),
    COALESCE(sales.i_category, returns.i_category),
    regexp_extract(COALESCE(sales.i_product_name, returns.i_product_name), '(\\w+)', 1),
    CONCAT('City_', COALESCE(sales.ca_city, returns.ca_city)),
    SUBSTRING(COALESCE(sales.ca_zip, returns.ca_zip), 1, 3)
ORDER BY total_sales_net_paid DESC
LIMIT 100
