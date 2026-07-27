/*
Goal: Produce a per‑brand sales summary that combines store and web channels, filtered by product, cost, price and customer attributes, then rank brands within each category and compare to overall web sales.
*/
WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_brand,
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price)               AS store_sales_amount,
        SUM(ws.ws_ext_sales_price)               AS web_sales_amount,
        COUNT(*)                                 AS transaction_count
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_page
        ON wp.wp_customer_sk = c_page.c_customer_sk
    WHERE
        i.i_units = 'Lb'                                          -- predicate 1
        AND i.i_manufact_id IN (26, 212, 294)                     -- predicate 2
        AND ss.ss_wholesale_cost > 20.00                         -- predicate 3
        AND ws.ws_sales_price BETWEEN 30.00 AND 90.00            -- predicate 4
        AND wp.wp_type = 'Content'                               -- predicate 5
        AND c.c_birth_year BETWEEN 1950 AND 1990                 -- predicate 6
    GROUP BY
        i.i_item_id,
        i.i_category,
        i.i_brand,
        c.c_customer_id
)
SELECT
    sa.i_category,
    sa.i_brand,
    SUM(sa.store_sales_amount)                         AS total_store_sales,
    SUM(sa.web_sales_amount)                           AS total_web_sales,
    SUM(sa.store_sales_amount + sa.web_sales_amount)  AS total_combined_sales,
    COUNT(DISTINCT sa.c_customer_id)                  AS unique_customers,
    AVG(sa.transaction_count)                         AS avg_transactions_per_customer,
    ROW_NUMBER() OVER (
        PARTITION BY sa.i_category
        ORDER BY SUM(sa.store_sales_amount + sa.web_sales_amount) DESC
    )                                                AS brand_rank_in_category,
    (SELECT SUM(ws2.ws_ext_sales_price)
       FROM web_sales ws2
       WHERE ws2.ws_sales_price > 0)               AS overall_web_sales
FROM sales_agg sa
GROUP BY
    sa.i_category,
    sa.i_brand
HAVING
    SUM(sa.store_sales_amount + sa.web_sales_amount) > 10000
ORDER BY
    total_combined_sales DESC
LIMIT 100
