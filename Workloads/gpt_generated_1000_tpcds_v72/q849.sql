WITH sales_agg AS (
   SELECT
        'web_sales' AS src,
        ws_ws.web_site_sk,
        ws_ws.web_site_id,
        td.t_hour,
        SUM(ws.ws_net_profit) AS total_amount
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_site ws_ws ON ws.ws_web_site_sk = ws_ws.web_site_sk
   WHERE ws_ws.web_city = 'Spring Hill'
     AND td.t_hour BETWEEN 9 AND 12
     AND EXISTS (
         SELECT 1
         FROM warehouse w
         WHERE w.w_city = ws_ws.web_city
           AND w.w_gmt_offset = -6.00
     )
   GROUP BY ws_ws.web_site_sk, ws_ws.web_site_id, td.t_hour
),
returns_agg AS (
   SELECT
        'store_returns' AS src,
        CAST(NULL AS integer) AS web_site_sk,
        CAST(NULL AS varchar) AS web_site_id,
        td.t_hour,
        SUM(sr.sr_net_loss) AS total_amount
   FROM store_returns sr
   JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   WHERE sr.sr_return_quantity > 10
     AND td.t_hour BETWEEN 9 AND 12
   GROUP BY td.t_hour
)
SELECT src, web_site_sk, web_site_id, t_hour, total_amount
FROM sales_agg
UNION ALL
SELECT src, web_site_sk, web_site_id, t_hour, total_amount
FROM returns_agg
ORDER BY total_amount DESC
LIMIT 100
