WITH store_returns_agg AS (
    SELECT
        d.d_year AS year,
        s.s_store_name AS name,
        'store_return' AS metric_type,
        CAST(SUM(sr.sr_net_loss) AS double) AS total_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_quantity > 1
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, s.s_store_name
),
web_site_agg AS (
    SELECT
        d.d_year AS year,
        w.web_name AS name,
        'web_open' AS metric_type,
        CAST(COUNT(*) AS double) AS total_amount
    FROM web_site w
    JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
    WHERE w.web_class = 'Unknown'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.web_name
)
SELECT *
FROM store_returns_agg
UNION ALL
SELECT *
FROM web_site_agg
ORDER BY year DESC, total_amount DESC
LIMIT 100
