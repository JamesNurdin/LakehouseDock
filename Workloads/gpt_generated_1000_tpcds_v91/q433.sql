WITH
    filtered_sales AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_item_sk,
            ws.ws_bill_customer_sk,
            ws.ws_order_number,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            ws.ws_ext_tax,
            ws.ws_ext_discount_amt,
            i.i_brand,
            i.i_category,
            i.i_item_desc,
            i.i_color,
            d.d_year,
            c.c_email_address,
            c.c_first_name,
            regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
            CASE WHEN regexp_like(c.c_email_address, '@example\\.com$') THEN 1 ELSE 0 END AS is_example_com
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2001
          AND regexp_like(i.i_item_desc, '(?i)computer|electronics')
          AND i.i_color LIKE 'B%'
          AND i.i_item_sk IN (
              SELECT cr_item_sk
              FROM catalog_returns
              WHERE cr_return_quantity > 0
          )
    ),
    intersected_customers AS (
        SELECT ws.ws_bill_customer_sk AS cust_sk
        FROM web_sales ws
        INTERSECT
        SELECT cr.cr_refunded_customer_sk AS cust_sk
        FROM catalog_returns cr
    )
SELECT
    concat(fs.i_brand, '-', fs.i_category) AS brand_category,
    substr(fs.i_color, 1, 1) AS color_initial,
    sum(fs.ws_ext_sales_price) AS total_sales,
    count(DISTINCT fs.ws_order_number) AS distinct_orders,
    sum(fs.ws_quantity) AS total_quantity,
    CASE WHEN sum(fs.ws_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_level,
    count(CASE WHEN fs.is_example_com = 1 THEN 1 END) AS example_com_customers
FROM filtered_sales fs
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN customer cust ON sr.sr_customer_sk = cust.c_customer_sk
    WHERE cust.c_customer_sk = fs.ws_bill_customer_sk
)
  AND fs.ws_bill_customer_sk IN (SELECT cust_sk FROM intersected_customers)
GROUP BY
    concat(fs.i_brand, '-', fs.i_category),
    substr(fs.i_color, 1, 1)
HAVING sum(fs.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
