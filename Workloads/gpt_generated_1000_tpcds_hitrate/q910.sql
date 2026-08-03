WITH
  agg_web_returns AS (
    SELECT
      wr_order_number,
      SUM(wr_return_amt) AS total_return_amt,
      SUM(wr_net_loss)   AS total_net_loss
    FROM web_returns
    WHERE wr_return_amt > 0
      AND wr_return_quantity >= 1
    GROUP BY wr_order_number
  ),
  store_sales_agg AS (
    SELECT
      ss_store_sk,
      ss_promo_sk,
      SUM(ss_net_paid) AS store_sales_net_paid,
      COUNT(*)          AS store_sales_cnt
    FROM store_sales
    WHERE ss_quantity >= 2
    GROUP BY ss_store_sk, ss_promo_sk
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY total_web_profit DESC)                               AS overall_rank,
  t.s_store_id,
  t.s_state,
  t.p_promo_id,
  t.p_channel_email,
  t.sm_type,
  t.w_city,
  t.total_web_profit,
  t.total_store_sales,
  t.total_return_amt,
  CASE WHEN t.total_web_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END       AS profit_flag,
  (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_cost > 0)                 AS max_promo_cost
FROM (
  SELECT
    s.s_store_id,
    s.s_state,
    p.p_promo_id,
    p.p_channel_email,
    sm.sm_type,
    w.w_city,
    SUM(ws.ws_net_profit)                         AS total_web_profit,
    SUM(ssa.store_sales_net_paid)                AS total_store_sales,
    COALESCE(SUM(r.total_return_amt), 0)          AS total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ws.ws_net_profit) DESC) AS store_rank
  FROM store s
  JOIN store_sales_agg ssa
    ON s.s_store_sk = ssa.ss_store_sk
  JOIN promotion p
    ON ssa.ss_promo_sk = p.p_promo_sk
  JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN agg_web_returns r
    ON ws.ws_order_number = r.wr_order_number
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_sales cs
    ON cs.cs_promo_sk = p.p_promo_sk
   AND cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   AND cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE p.p_cost > 500
    AND sm.sm_type = 'AIR'
    AND w.w_city = 'Los Angeles'
    AND s.s_state = 'CA'
    AND web.web_name LIKE '%Shop%'
    AND ws.ws_quantity >= 2
    AND cs.cs_quantity >= 2
  GROUP BY
    s.s_store_id,
    s.s_state,
    p.p_promo_id,
    p.p_channel_email,
    sm.sm_type,
    w.w_city
) t
WHERE t.store_rank <= 3
ORDER BY t.total_web_profit DESC
LIMIT 100
