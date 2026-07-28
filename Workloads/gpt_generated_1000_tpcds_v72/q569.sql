-- goal: Compare aggregated sales, returns and inventory metrics for preferred vs non‑preferred customers, 
-- applying multiple filters, using CTEs, subqueries, CASE, window functions and a UNION ALL set operation.
WITH
    pref_data AS (
        SELECT
            c.c_customer_id,
            c.c_preferred_cust_flag,
            c.c_birth_year,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            ss.ss_ext_sales_price      AS store_sales_price,
            ws.ws_ext_sales_price      AS web_sales_price,
            sr.sr_return_amt           AS return_amount,
            inv.inv_quantity_on_hand   AS inventory_qty,
            ws.ws_list_price           AS web_list_price
        FROM customer c
        JOIN store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store_returns sr
            ON sr.sr_customer_sk = c.c_customer_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN item i
            ON i.i_item_sk = ss.ss_item_sk
           AND i.i_item_sk = sr.sr_item_sk
        JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
           AND ws.ws_item_sk = i.i_item_sk
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        WHERE i.i_class_id IN (2, 5, 8)
          AND i.i_brand_id = 2004001
          AND c.c_preferred_cust_flag = 'Y'
          AND c.c_birth_year BETWEEN 1970 AND 1990
          AND ws.ws_list_price > 100
          AND ss.ss_quantity >= 2
          AND sr.sr_return_quantity >= 0
    ),
    nonpref_data AS (
        SELECT
            c.c_customer_id,
            c.c_preferred_cust_flag,
            c.c_birth_year,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            ss.ss_ext_sales_price      AS store_sales_price,
            ws.ws_ext_sales_price      AS web_sales_price,
            sr.sr_return_amt           AS return_amount,
            inv.inv_quantity_on_hand   AS inventory_qty,
            ws.ws_list_price           AS web_list_price
        FROM customer c
        JOIN store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store_returns sr
            ON sr.sr_customer_sk = c.c_customer_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN item i
            ON i.i_item_sk = ss.ss_item_sk
           AND i.i_item_sk = sr.sr_item_sk
        JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
           AND ws.ws_item_sk = i.i_item_sk
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
        WHERE i.i_class_id IN (2, 5, 8)
          AND i.i_brand_id = 2004001
          AND c.c_preferred_cust_flag = 'N'
          AND c.c_birth_year BETWEEN 1970 AND 1990
          AND ws.ws_list_price > 100
          AND ss.ss_quantity >= 2
          AND sr.sr_return_quantity >= 0
    )
SELECT
    i_item_id,
    i_product_name,
    i_category,
    SUM(store_sales_price)               AS total_store_sales,
    SUM(web_sales_price)                 AS total_web_sales,
    SUM(return_amount)                   AS total_return_amount,
    AVG(inventory_qty)                   AS avg_inventory_qty,
    COUNT(DISTINCT c_customer_id)        AS distinct_customers,
    CASE WHEN SUM(store_sales_price) > 10000 THEN 'Big' ELSE 'Small' END AS sales_size,
    (SELECT AVG(store_sales_price) FROM pref_data) AS avg_store_sales_pref,
    RANK() OVER (ORDER BY SUM(store_sales_price) DESC) AS sales_rank
FROM pref_data
GROUP BY i_item_id, i_product_name, i_category
HAVING SUM(store_sales_price) > 5000

UNION ALL

SELECT
    i_item_id,
    i_product_name,
    i_category,
    SUM(store_sales_price)               AS total_store_sales,
    SUM(web_sales_price)                 AS total_web_sales,
    SUM(return_amount)                   AS total_return_amount,
    AVG(inventory_qty)                   AS avg_inventory_qty,
    COUNT(DISTINCT c_customer_id)        AS distinct_customers,
    CASE WHEN SUM(store_sales_price) > 8000 THEN 'Big' ELSE 'Small' END AS sales_size,
    (SELECT AVG(store_sales_price) FROM nonpref_data) AS avg_store_sales_nonpref,
    RANK() OVER (ORDER BY SUM(store_sales_price) DESC) AS sales_rank
FROM nonpref_data
GROUP BY i_item_id, i_product_name, i_category
HAVING SUM(store_sales_price) > 4000

ORDER BY total_store_sales DESC
LIMIT 100
