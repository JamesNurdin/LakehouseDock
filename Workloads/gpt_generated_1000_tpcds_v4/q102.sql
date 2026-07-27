WITH site_agg AS (
    SELECT
        ws.web_open_date_sk,
        COUNT(*) AS sites_opened,
        AVG(ws.web_gmt_offset) AS avg_gmt_offset,
        COUNT(DISTINCT ws.web_county) AS distinct_counties
    FROM web_site ws
    WHERE ws.web_state = 'CA'
      AND ws.web_country = 'United States'
      AND ws.web_gmt_offset BETWEEN -8.00 AND -5.00
      AND ws.web_mkt_id IN (1, 2, 3)
    GROUP BY ws.web_open_date_sk
)
SELECT DISTINCT
    dd.d_year,
    dd.d_quarter_seq,
    sa.sites_opened,
    ROUND(sa.avg_gmt_offset, 2) AS avg_gmt_offset,
    sa.distinct_counties,
    dd.d_weekend
FROM site_agg sa
JOIN date_dim dd
    ON sa.web_open_date_sk = dd.d_date_sk
WHERE dd.d_quarter_seq = 12
  AND dd.d_weekend = 'N'
  AND dd.d_dow = 3
  AND dd.d_year BETWEEN 2000 AND 2005
ORDER BY dd.d_year DESC, dd.d_quarter_seq ASC
LIMIT 100
