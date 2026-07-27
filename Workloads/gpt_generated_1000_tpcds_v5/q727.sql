WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_qty_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_store_sk, s.s_store_name, i.i_item_sk, i.i_item_id
    HAVING SUM(ss.ss_quantity) > 100
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_item_id,
        SUM(sr.sr_return_quantity) AS total_qty_returned,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY s.s_store_sk, s.s_store_name, i.i_item_sk, i.i_item_id
    HAVING SUM(sr.sr_return_quantity) > 20
)
SELECT DISTINCT
    sa.s_store_name        AS store_name,
    sa.i_item_id           AS item_id,
    'sales'                AS metric_type,
    sa.total_qty_sold      AS quantity,
    sa.total_sales_amount  AS amount,
    (
        SELECT COUNT(DISTINCT ss2.ss_customer_sk)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = sa.s_store_sk
          AND ss2.ss_item_sk = sa.i_item_sk
    )                      AS distinct_customers
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss3
    JOIN web_page wp ON ss3.ss_customer_sk = wp.wp_customer_sk
    WHERE ss3.ss_store_sk = sa.s_store_sk
      AND ss3.ss_item_sk = sa.i_item_sk
      AND wp.wp_type = 'product'
)
UNION ALL
SELECT
    ra.s_store_name        AS store_name,
    ra.i_item_id           AS item_id,
    'returns'              AS metric_type,
    ra.total_qty_returned  AS quantity,
    ra.total_return_amount AS amount,
    NULL                   AS distinct_customers
FROM returns_agg ra
ORDER BY store_name, item_id, metric_type
LIMIT 100
