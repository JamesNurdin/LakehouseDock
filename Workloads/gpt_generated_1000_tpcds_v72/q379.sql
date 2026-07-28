WITH catalog_agg AS (
  SELECT
    i.i_category AS category,
    CONCAT(cc.cc_state, '-', cc.cc_city) AS region,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS order_cnt,
    CASE
      WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0) > 0.20 THEN 'HIGH'
      WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0) > 0.10 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_bucket
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE regexp_like(i.i_item_desc, '^.*(Large|Medium|Small).*$')
    AND cc.cc_city LIKE '%County%'
    AND td.t_hour BETWEEN 9 AND 17
  GROUP BY i.i_category, CONCAT(cc.cc_state, '-', cc.cc_city)
),

web_agg AS (
  SELECT
    i.i_category AS category,
    CONCAT('WEB-', i.i_color) AS region,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt,
    CASE
      WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.15 THEN 'HIGH'
      WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.05 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_bucket
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE regexp_extract(i.i_item_id, '(\\d{3})$', 1) IS NOT NULL
    AND i.i_container = 'Unknown'
    AND td.t_hour BETWEEN 9 AND 17
  GROUP BY i.i_category, CONCAT('WEB-', i.i_color)
)

SELECT
  category,
  region,
  SUM(total_sales) AS combined_sales,
  SUM(total_profit) AS combined_profit,
  SUM(order_cnt) AS combined_orders,
  CASE
    WHEN SUM(total_profit) / NULLIF(SUM(total_sales), 0) > 0.18 THEN 'VERY HIGH'
    ELSE 'OTHER'
  END AS overall_profit_bucket
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
) combined
GROUP BY category, region
ORDER BY combined_sales DESC
LIMIT 100
