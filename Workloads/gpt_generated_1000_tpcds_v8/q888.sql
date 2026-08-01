/*
Goal: Compare total sales by item and date across store and web channels, categorizing items, sampling web sales, excluding a specific item class, and assigning a global row number.
*/
WITH ss_data AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id AS item_id,
        CASE
            WHEN i.i_class = 'infants' THEN 'Infant'
            WHEN i.i_class = 'dresses' THEN 'Dress'
            ELSE 'Other'
        END AS item_category,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i            ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_item_sk NOT IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_class = 'infants'
    )
    GROUP BY d.d_date, i.i_item_id, i.i_class
),
ws_data AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id AS item_id,
        CASE
            WHEN i.i_class = 'infants' THEN 'Infant'
            WHEN i.i_class = 'dresses' THEN 'Dress'
            ELSE 'Other'
        END AS item_category,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i            ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_item_sk NOT IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_class = 'infants'
    )
    GROUP BY d.d_date, i.i_item_id, i.i_class
)
SELECT
    sale_date,
    item_id,
    item_category,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM (
    SELECT * FROM ss_data
    UNION
    SELECT * FROM ws_data
) AS combined
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
