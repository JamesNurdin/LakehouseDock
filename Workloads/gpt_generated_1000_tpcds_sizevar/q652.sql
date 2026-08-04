WITH item_sales AS (
    SELECT
        ss.ss_item_sk,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS tx_count,
        AVG(ss.ss_net_paid_inc_tax) AS avg_paid_inc_tax
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY ss.ss_item_sk, i.i_category_id, i.i_category
),

inventory_items AS (
    SELECT DISTINCT inv.inv_item_sk
    FROM inventory inv
    JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
    JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk
    WHERE d2.d_year = 2001
),

intersect_items AS (
    SELECT ss_item_sk FROM item_sales
    INTERSECT
    SELECT inv_item_sk FROM inventory_items
),

scalar_max_profit AS (
    SELECT MAX(ss_net_profit) AS max_profit FROM store_sales
)

SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    t.t_hour,
    s.s_store_name,
    SUM(ss.ss_ext_sales_price) AS daily_sales,
    CASE
        WHEN SUM(ss.ss_net_profit) > (SELECT max_profit FROM scalar_max_profit) THEN 'Above Max'
        ELSE 'Below Max'
    END AS profit_category,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS category_sales_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS overall_sales_rank
FROM store_sales ss
JOIN intersect_items ii ON ss.ss_item_sk = ii.ss_item_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE
    d.d_month_seq BETWEEN 1200 AND 1220
    AND t.t_hour BETWEEN 9 AND 17
    AND s.s_state = 'CA'
    AND i.i_brand_id IN (1, 2, 3)
    AND ss.ss_quantity > 1
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    t.t_hour,
    s.s_store_name,
    i.i_category
HAVING
    SUM(ss.ss_ext_sales_price) > 1000
ORDER BY daily_sales DESC
OFFSET 0
LIMIT 100
