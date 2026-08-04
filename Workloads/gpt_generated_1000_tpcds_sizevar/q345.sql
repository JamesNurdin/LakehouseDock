WITH catalog_agg AS (
   SELECT
       cc.cc_name AS sales_channel,
       d.d_year,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY GROUPING SETS (
       (cc.cc_name, d.d_year),
       (d.d_year)
   )
),
web_agg AS (
   SELECT
       wsit.web_name AS sales_channel,
       d.d_year,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(*) AS order_cnt
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY GROUPING SETS (
       (wsit.web_name, d.d_year),
       (d.d_year)
   )
),
combined AS (
   SELECT sales_channel, d_year, total_net_paid, order_cnt FROM catalog_agg
   UNION
   SELECT sales_channel, d_year, total_net_paid, order_cnt FROM web_agg
)
SELECT
    r.segment,
    c.sales_channel,
    c.d_year,
    c.total_net_paid,
    c.order_cnt
FROM combined c
CROSS JOIN (VALUES 'NorthAmerica', 'Europe') AS r(segment)
ORDER BY c.total_net_paid DESC, r.segment
LIMIT 100
