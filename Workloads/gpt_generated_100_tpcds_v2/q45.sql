WITH sr AS (
    SELECT
        CAST(sr_reason_sk AS varchar) AS category,
        CAST(SUM(sr_net_loss) AS double) AS metric,
        COUNT(*) AS cnt,
        'store_returns' AS source
    FROM store_returns
    WHERE sr_net_loss > 100
    GROUP BY sr_reason_sk
),
wp AS (
    SELECT
        wp_type AS category,
        CAST(SUM(wp_char_count) AS double) AS metric,
        COUNT(*) AS cnt,
        'web_page' AS source
    FROM web_page
    WHERE wp_rec_end_date >= DATE '2000-01-01'
    GROUP BY wp_type
)
SELECT category, metric, cnt, source FROM sr
UNION ALL
SELECT category, metric, cnt, source FROM wp
