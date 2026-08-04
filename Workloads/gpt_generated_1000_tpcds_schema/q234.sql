WITH
  promo_sel AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_channel_tv = 'N' AND p_channel_demo = 'N'
  ),
  intersect_promos AS (
    SELECT cs_promo_sk AS promo_sk
    FROM catalog_sales
    INTERSECT
    SELECT ss_promo_sk
    FROM store_sales
  ),
  avg_profit AS (
    SELECT cs_promo_sk, AVG(cs_net_profit) AS avg_cs_profit
    FROM catalog_sales
    GROUP BY cs_promo_sk
  ),
  main AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      p.p_promo_name,
      t.t_hour,
      w.w_warehouse_name,
      ss.ss_quantity,
      ws.ws_quantity,
      ws.ws_net_profit AS ws_net_profit,
      LAG(cs.cs_net_paid) OVER (PARTITION BY cs.cs_promo_sk ORDER BY cs.cs_sold_date_sk) AS lag_cs_net_paid,
      ap.avg_cs_profit,
      (SELECT MAX(p_cost) FROM promotion WHERE p_promo_sk = cs.cs_promo_sk) AS max_promo_cost
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
      ON ss.ss_sold_time_sk = t.t_time_sk
      AND ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_time_sk = t.t_time_sk
      AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN avg_profit ap ON cs.cs_promo_sk = ap.cs_promo_sk
    WHERE
      cs.cs_promo_sk IN (SELECT promo_sk FROM intersect_promos)
      AND cs.cs_promo_sk IN (SELECT p_promo_sk FROM promo_sel)
      AND cs.cs_promo_sk NOT IN (SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y')
      AND w.w_zip = '58828'
      AND cs.cs_ext_list_price > 1000
  )
SELECT
  cs_order_number,
  cs_sold_date_sk,
  cs_net_paid,
  cs_net_profit,
  p_promo_name,
  t_hour,
  w_warehouse_name,
  ss_quantity,
  ws_quantity,
  ws_net_profit,
  lag_cs_net_paid,
  avg_cs_profit,
  max_promo_cost,
  SUM(cs_net_paid) OVER (PARTITION BY p_promo_name ORDER BY cs_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid
FROM main
ORDER BY cs_sold_date_sk DESC, cs_order_number
LIMIT 100
