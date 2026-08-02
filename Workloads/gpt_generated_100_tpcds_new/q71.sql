WITH sales_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_category
),
returns_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS total_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_category
),
combined AS (
    SELECT item_id, category, total_sales AS metric, 'sales' AS source
    FROM sales_data
    UNION ALL
    SELECT item_id, category, total_returns AS metric, 'returns' AS source
    FROM returns_data
)
SELECT DISTINCT
    c.item_id,
    c.category,
    c.metric,
    c.source
FROM combined c
WHERE c.item_id NOT IN (
    SELECT DISTINCT i.i_item_id
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
)
ORDER BY c.metric DESC
LIMIT 100
