WITH
  store_agg AS (
    SELECT
      s.s_store_name          AS channel_name,
      i.i_category            AS product_category,
      CAST('store' AS VARCHAR) AS channel_type,
      SUM(ss.ss_net_profit)   AS total_profit,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE i.i_category = 'Sports'
    GROUP BY GROUPING SETS (
      (s.s_store_name, i.i_category),
      (s.s_store_name),
      (i.i_category),
      ()
    )
  ),
  web_agg AS (
    SELECT
      wsit.web_name            AS channel_name,
      i.i_category             AS product_category,
      CAST('web' AS VARCHAR)   AS channel_type,
      SUM(ws.ws_net_profit)    AS total_profit,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      CASE WHEN SUM(ws.ws_net_profit) > 8000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_category = 'Sports'
    GROUP BY GROUPING SETS (
      (wsit.web_name, i.i_category),
      (wsit.web_name),
      (i.i_category),
      ()
    )
  )
SELECT
  channel_name,
  product_category,
  channel_type,
  total_profit,
  total_sales,
  profit_level
FROM (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
) combined
ORDER BY total_profit DESC
LIMIT 100
