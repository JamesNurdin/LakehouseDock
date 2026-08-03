WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS metric_value,
        'SALES' AS metric_type,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS level,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_tax_percentage >= 0.08
    GROUP BY GROUPING SETS ( (s.s_store_id, i.i_category), (s.s_store_id), (i.i_category) )
),
returns_agg AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS metric_value,
        'RETURNS' AS metric_type,
        CASE WHEN SUM(sr.sr_return_amt) > 50000 THEN 'HIGH' ELSE 'LOW' END AS level,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(sr.sr_return_amt) DESC) AS rn
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE s.s_tax_percentage < 0.10
    GROUP BY GROUPING SETS ( (s.s_store_id, i.i_category), (s.s_store_id), (i.i_category) )
)
SELECT
    u.store_id,
    u.category,
    u.metric_type,
    u.metric_value,
    u.level,
    u.rn,
    t.tag
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) u
CROSS JOIN UNNEST(array['NEW', 'OLD']) AS t(tag)
ORDER BY u.metric_value DESC
OFFSET 10 ROWS
LIMIT 100
