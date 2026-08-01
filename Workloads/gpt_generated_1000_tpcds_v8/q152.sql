WITH sales_agg AS (
  SELECT
    s.s_store_name                AS store_name,
    d.d_month_seq                AS month_seq,
    p.p_promo_name               AS promo_name,
    SUM(ss.ss_net_profit)        AS store_sales_profit,
    SUM(ws.ws_net_profit)        AS web_sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_returns_loss,
    SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) -
    SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_profit
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
  LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND ib.ib_upper_bound >= 50000
    AND r.r_reason_desc LIKE '%Defect%'
    AND t.t_am_pm = 'PM'
  GROUP BY GROUPING SETS (
    (s.s_store_name, d.d_month_seq, p.p_promo_name),
    (s.s_store_name, d.d_month_seq),
    (s.s_store_name),
    ()
  )
)
SELECT
  store_name,
  month_seq,
  promo_name,
  store_sales_profit,
  web_sales_profit,
  total_returns_loss,
  total_profit,
  ROW_NUMBER() OVER (PARTITION BY month_seq ORDER BY total_profit DESC) AS store_month_rank
FROM sales_agg
ORDER BY month_seq, store_month_rank
LIMIT 100
