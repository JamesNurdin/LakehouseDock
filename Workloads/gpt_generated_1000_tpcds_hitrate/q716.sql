WITH
  agg_sales AS (
    SELECT
      ws_order_number,
      ws_item_sk,
      ws_promo_sk,
      ws_sold_time_sk,
      ws_ship_mode_sk,
      ws_warehouse_sk,
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk,
      ws_web_page_sk,
      ws_web_site_sk,
      SUM(ws_ext_sales_price)   AS total_sales,
      SUM(ws_net_profit)        AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2450900
    GROUP BY
      ws_order_number,
      ws_item_sk,
      ws_promo_sk,
      ws_sold_time_sk,
      ws_ship_mode_sk,
      ws_warehouse_sk,
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk,
      ws_web_page_sk,
      ws_web_site_sk
  ),
  agg_returns AS (
    SELECT
      cr_refunded_customer_sk,
      cr_catalog_page_sk,
      SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450815 AND 2450900
    GROUP BY cr_refunded_customer_sk, cr_catalog_page_sk
  )
SELECT
  p.p_promo_name,
  t.t_hour,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  SUM(s.total_sales)  AS sum_sales,
  SUM(s.total_profit) AS sum_profit,
  SUM(r.total_return_amount) AS sum_returns
FROM agg_sales s
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON s.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws ON s.ws_web_site_sk = ws.web_site_sk
JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON s.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN agg_returns r ON r.cr_refunded_customer_sk = c.c_customer_sk
JOIN (
  SELECT *
  FROM catalog_page
  TABLESAMPLE BERNOULLI (10)
) cp ON r.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
  ib.ib_lower_bound >= 50000
  AND ib.ib_upper_bound <= 150000
  AND p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
  AND EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = s.ws_order_number
      AND wr.wr_refunded_customer_sk = c.c_customer_sk
  )
GROUP BY
  p.p_promo_name,
  t.t_hour,
  ib.ib_lower_bound,
  ib.ib_upper_bound
HAVING
  SUM(s.total_sales) > 100000
ORDER BY
  sum_sales DESC
LIMIT 100
