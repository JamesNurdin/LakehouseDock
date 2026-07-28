WITH sales_data AS (
  SELECT
    cc.cc_division_name,
    i1.i_class,
    td1.t_hour,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) AS total_profit,
    (
      SELECT COUNT(*)
      FROM web_sales ws2
      WHERE ws2.ws_item_sk = i1.i_item_sk
        AND ws2.ws_sold_date_sk = cs.cs_sold_date_sk
    ) AS related_web_sales_cnt
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm1
    ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
  JOIN item i1
    ON cs.cs_item_sk = i1.i_item_sk
  JOIN promotion p1
    ON cs.cs_promo_sk = p1.p_promo_sk
  JOIN time_dim td1
    ON cs.cs_sold_time_sk = td1.t_time_sk

  -- store_sales and its dimensions (different aliases)
  JOIN store_sales ss
    ON 1 = 1
  JOIN time_dim td2
    ON ss.ss_sold_time_sk = td2.t_time_sk
  JOIN item i2
    ON ss.ss_item_sk = i2.i_item_sk

  -- web_sales and its dimensions (different aliases)
  JOIN web_sales ws
    ON 1 = 1
  JOIN item i3
    ON ws.ws_item_sk = i3.i_item_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN ship_mode sm3
    ON ws.ws_ship_mode_sk = sm3.sm_ship_mode_sk
  JOIN promotion p3
    ON ws.ws_promo_sk = p3.p_promo_sk
  JOIN time_dim td3
    ON ws.ws_sold_time_sk = td3.t_time_sk

  GROUP BY
    cc.cc_division_name,
    i1.i_class,
    td1.t_hour,
    cs.cs_sold_date_sk,
    i1.i_item_sk
)
SELECT
  cc_division_name,
  i_class,
  t_hour,
  catalog_profit,
  store_profit,
  web_profit,
  total_profit,
  related_web_sales_cnt
FROM sales_data
ORDER BY total_profit DESC
LIMIT 100
