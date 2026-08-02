/*
Goal: Compare and rank the highest net‑loss periods for physical stores versus web sites by year, showing the top 5 rows per source (store or web) for Saturdays.
*/
WITH
store_agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        SUM(sr.sr_net_loss) AS total_net_loss,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_day_name = 'Saturday'
    GROUP BY d.d_year, s.s_store_name
),
web_agg AS (
    SELECT
        d.d_year,
        ws.web_name,
        SUM(wr.wr_net_loss) AS total_net_loss,
        'web' AS source
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_day_name = 'Saturday'
    GROUP BY d.d_year, ws.web_name
)
SELECT
    year,
    name,
    total_net_loss,
    source
FROM (
    SELECT
        year,
        name,
        total_net_loss,
        source,
        ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_net_loss DESC) AS rn
    FROM (
        SELECT
            d_year AS year,
            s_store_name AS name,
            total_net_loss,
            source
        FROM store_agg
        UNION ALL
        SELECT
            d_year AS year,
            web_name AS name,
            total_net_loss,
            source
        FROM web_agg
    ) u
) ranked
WHERE rn <= 5
ORDER BY source, total_net_loss DESC
LIMIT 100
