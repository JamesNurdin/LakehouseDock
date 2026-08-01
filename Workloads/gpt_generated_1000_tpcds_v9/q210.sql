WITH store_returns_agg AS (
    SELECT d.d_year AS year,
           s.s_store_name AS entity_name,
           'store' AS source,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year IN (2000, 2001)
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY d.d_year, s.s_store_name
),
web_returns_agg AS (
    SELECT d.d_year AS year,
           wp.wp_url AS entity_name,
           'web' AS source,
           SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year IN (2000, 2001)
      AND wp.wp_autogen_flag = 'N'
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY d.d_year, wp.wp_url
)
SELECT year,
       entity_name,
       source,
       total_net_loss
FROM store_returns_agg
UNION ALL
SELECT year,
       entity_name,
       source,
       total_net_loss
FROM web_returns_agg
ORDER BY year, total_net_loss DESC
LIMIT 100
