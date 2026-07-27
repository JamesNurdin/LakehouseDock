WITH base AS (
  SELECT
    s.s_store_id,
    s.s_state,
    cp.cp_catalog_page_id,
    d_ss.d_year,
    d_ss.d_date,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_id        AS p_promo_id,
    p.p_discount_active AS p_discount_active,
    ss.ss_ext_sales_price,
    ss.ss_net_profit    AS ss_net_profit,
    ws.ws_ext_sales_price,
    ws.ws_net_profit    AS ws_net_profit,
    sr.sr_net_loss,
    wr.wr_net_loss,
    td1.t_hour
  FROM catalog_page cp
  JOIN date_dim d_cp      ON cp.cp_start_date_sk = d_cp.d_date_sk
  JOIN store s            ON s.s_closed_date_sk = d_cp.d_date_sk
  JOIN store_sales ss     ON ss.ss_store_sk = s.s_store_sk
                         AND ss.ss_sold_date_sk = d_cp.d_date_sk
  JOIN date_dim d_ss      ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN time_dim td1       ON ss.ss_sold_time_sk = td1.t_time_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib          ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p             ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store_returns sr        ON sr.sr_store_sk = s.s_store_sk
                         AND sr.sr_returned_date_sk = d_ss.d_date_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
  JOIN date_dim d_sr      ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN web_sales ws      ON ws.ws_sold_date_sk = d_ss.d_date_sk
                         AND ws.ws_item_sk = ss.ss_item_sk
  JOIN date_dim d_ws      ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN web_page wp        ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN warehouse w        ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td2       ON ws.ws_sold_time_sk = td2.t_time_sk
  JOIN web_returns wr    ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_returned_date_sk = d_ws.d_date_sk
                         AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d_wr      ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN time_dim td3       ON wr.wr_returned_time_sk = td3.t_time_sk
  WHERE d_ss.d_year = 2000
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 30000
    AND s.s_state = 'CA'
),
agg AS (
  SELECT
    s_store_id,
    s_state,
    d_year,
    COUNT(DISTINCT p_promo_id)                           AS distinct_promos,
    SUM(COALESCE(ss_ext_sales_price, 0) + COALESCE(ws_ext_sales_price, 0)) AS total_sales,
    SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(sr_net_loss, 0) - COALESCE(wr_net_loss, 0)) AS net_profit,
    CASE WHEN SUM(COALESCE(ss_ext_sales_price, 0) + COALESCE(ws_ext_sales_price, 0)) > 1000000
         THEN 'HIGH' ELSE 'NORMAL' END                AS sales_category
  FROM base
  GROUP BY s_store_id, s_state, d_year
)
SELECT
  s_store_id,
  s_state,
  d_year,
  sales_category,
  total_sales,
  net_profit,
  distinct_promos,
  AVG(net_profit) OVER (PARTITION BY s_state) AS avg_state_net_profit,
  (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper,
  CASE WHEN EXISTS (
    SELECT 1 FROM promotion p2 WHERE p2.p_cost > 1000 AND p2.p_discount_active = 'Y'
  ) THEN 'YES' ELSE 'NO' END                         AS any_high_cost_promo
FROM agg
ORDER BY net_profit DESC
LIMIT 100
