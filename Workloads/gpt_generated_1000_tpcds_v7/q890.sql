WITH store_returns_agg AS (
    SELECT
        'store_returns' AS source,
        d.d_year AS year,
        SUM(sr.sr_net_loss) AS metric_value
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND t.t_time BETWEEN 9 AND 16
    GROUP BY d.d_year
),
web_page_agg AS (
    SELECT
        'web_page' AS source,
        d.d_year AS year,
        SUM(wp.wp_char_count) AS metric_value
    FROM web_page wp
    JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wp.wp_char_count > 2000
    GROUP BY d.d_year
)
SELECT source, year, metric_value
FROM store_returns_agg
UNION ALL
SELECT source, year, metric_value
FROM web_page_agg
ORDER BY year, source
