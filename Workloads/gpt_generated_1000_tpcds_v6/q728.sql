WITH catalog_agg AS (
  SELECT
    td.t_hour,
    td.t_sub_shift,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE td.t_sub_shift = 'morning'
    AND cs.cs_ext_discount_amt > 1000
    AND EXISTS (
        SELECT 1
        FROM time_dim td2
        WHERE td2.t_time_sk = cs.cs_sold_time_sk
          AND td2.t_minute IN (5, 7, 18)
    )
  GROUP BY td.t_hour, td.t_sub_shift
),
web_agg AS (
  SELECT
    td.t_hour,
    td.t_sub_shift,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE td.t_sub_shift = 'evening'
    AND ws.ws_coupon_amt > 500
    AND td.t_minute IN (6, 17)
  GROUP BY td.t_hour, td.t_sub_shift
)
SELECT
  t_hour,
  t_sub_shift,
  total_sales,
  total_profit,
  order_cnt
FROM catalog_agg
UNION ALL
SELECT
  t_hour,
  t_sub_shift,
  total_sales,
  total_profit,
  order_cnt
FROM web_agg
ORDER BY t_hour, total_sales DESC
LIMIT 100
