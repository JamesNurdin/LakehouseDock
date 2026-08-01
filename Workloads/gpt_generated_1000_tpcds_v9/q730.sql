WITH sales AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS amount,
        'sales' AS metric_type
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451060
      AND s.s_state = 'CA'
      AND i.i_size IN ('large', 'medium')
    GROUP BY s.s_store_name, i.i_category
),
returns AS (
    SELECT
        NULL AS store_name,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS amount,
        'returns' AS metric_type
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2451060
      AND i.i_size = 'medium'
    GROUP BY i.i_category
),
combined AS (
    SELECT metric_type, store_name, category, amount FROM sales
    UNION ALL
    SELECT metric_type, store_name, category, amount FROM returns
),
aggregated AS (
    SELECT
        metric_type,
        store_name,
        category,
        SUM(amount) AS total_amount
    FROM combined
    GROUP BY GROUPING SETS (
        (metric_type, store_name, category),
        (metric_type, store_name),
        (metric_type, category),
        (metric_type)
    )
)
SELECT
    metric_type,
    COALESCE(store_name, 'All Stores') AS store_name,
    category,
    total_amount,
    ROW_NUMBER() OVER (PARTITION BY metric_type ORDER BY total_amount DESC) AS rank_metric,
    SUM(total_amount) OVER (PARTITION BY metric_type, store_name) AS store_metric_total
FROM aggregated
ORDER BY metric_type, store_name, category
LIMIT 100
