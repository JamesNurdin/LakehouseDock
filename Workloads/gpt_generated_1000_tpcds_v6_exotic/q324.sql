WITH filtered_data AS (
  SELECT
    s.s_store_id,
    i.i_category,
    d1.d_year,
    ss.ss_net_profit,
    ss.ss_net_paid_inc_tax,
    ws.ws_net_profit AS ws_net_profit,
    cr.cr_return_amount,
    CASE
      WHEN ss.ss_net_profit > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = ss.ss_store_sk
      ) THEN 'Above Avg'
      ELSE 'Below Avg'
    END AS profit_category
  FROM store_sales ss
  JOIN date_dim d1
    ON ss.ss_sold_date_sk = d1.d_date_sk
  JOIN time_dim t1
    ON ss.ss_sold_time_sk = t1.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
       AND ib.ib_lower_bound >= 50000
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d1.d_date_sk
   AND ws.ws_sold_time_sk = t1.t_time_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_promo_sk = p.p_promo_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d1.d_date_sk
   AND cr.cr_returned_time_sk = t1.t_time_sk
   AND cr.cr_item_sk = i.i_item_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd_cr_refunded
    ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
  WHERE d1.d_year = 2001
    AND s.s_gmt_offset = -6.00
    AND i.i_current_price BETWEEN 50 AND 200
)
SELECT
  s_store_id,
  i_category,
  d_year,
  profit_category,
  SUM(ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
  COUNT(*) AS sales_transactions,
  AVG(ws_net_profit) AS avg_web_profit,
  MIN(cr_return_amount) AS min_return_amount,
  MAX(cr_return_amount) AS max_return_amount
FROM filtered_data
GROUP BY s_store_id, i_category, d_year, profit_category
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
