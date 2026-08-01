WITH returns_agg AS (
    SELECT
        s.s_store_id,
        concat(s.s_store_name, ' - ', s.s_city) AS store_label,
        sr_agg.total_net_loss AS amount,
        CASE
            WHEN sr_agg.total_net_loss > 5000 THEN 'HighLoss'
            ELSE 'LowLoss'
        END AS category,
        'StoreReturn' AS source_type
    FROM store s
    CROSS JOIN LATERAL (
        SELECT SUM(sr.sr_net_loss) AS total_net_loss
        FROM store_returns sr
        WHERE sr.sr_store_sk = s.s_store_sk
    ) AS sr_agg
    WHERE s.s_city LIKE '%Lake%'
      AND regexp_like(s.s_store_name, '^.*Store.*$')
      AND regexp_extract(s.s_zip, '(\\d{5})') IS NOT NULL
),
sales_agg AS (
    SELECT
        s.s_store_id,
        concat(s.s_store_name, ' - ', s.s_city) AS store_label,
        SUM(ss.ss_net_paid) AS amount,
        CASE
            WHEN SUM(ss.ss_net_paid) > 10000 THEN 'HighSales'
            ELSE 'LowSales'
        END AS category,
        'StoreSales' AS source_type
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_city LIKE '%Lake%'
      AND regexp_like(s.s_store_name, '^.*Store.*$')
      AND regexp_extract(s.s_zip, '(\\d{5})') IS NOT NULL
    GROUP BY s.s_store_id, s.s_store_name, s.s_city
)
SELECT
    combined.s_store_id,
    combined.store_label,
    combined.amount,
    combined.category,
    combined.source_type
FROM (
    SELECT s_store_id, store_label, amount, category, source_type FROM returns_agg
    UNION ALL
    SELECT s_store_id, store_label, amount, category, source_type FROM sales_agg
) AS combined
ORDER BY combined.amount DESC, combined.source_type
LIMIT 100
