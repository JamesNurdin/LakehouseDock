WITH base AS (
  SELECT
    p.p_promo_id AS promo_id,
    sm.sm_ship_mode_id AS ship_mode_id,
    w.w_warehouse_id AS warehouse_id,
    ib.ib_upper_bound,
    d_cs.d_year AS year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amt,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amt
  FROM catalog_sales cs
  JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN store_sales ss
    ON ss.ss_item_sk = cs.cs_item_sk
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = cs.cs_item_sk
  LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site ws
    ON ws.web_open_date_sk = wp.wp_creation_date_sk
  WHERE p.p_channel_dmail = 'Y'
    AND ca_bill.ca_state = 'CA'
    AND w.w_city = 'Los Angeles'
    AND d_cs.d_year = 2001
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_sales_price > (
          SELECT MAX(cs2.cs_sales_price)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = d_cs.d_date_sk
        )
    AND EXISTS (
          SELECT 1
          FROM income_band ib2
          WHERE ib2.ib_upper_bound < 200000
            AND ib2.ib_income_band_sk = hd_bill.hd_income_band_sk
        )
  GROUP BY p.p_promo_id, sm.sm_ship_mode_id, w.w_warehouse_id, ib.ib_upper_bound, d_cs.d_year
)
SELECT
  promo_id,
  ship_mode_id,
  warehouse_id,
  year,
  total_sales,
  total_profit,
  order_cnt,
  total_returns,
  store_return_amt,
  web_return_amt,
  total_profit / NULLIF(total_sales, 0) AS profit_margin
FROM base
WHERE total_sales > (SELECT AVG(total_sales) FROM base)
ORDER BY profit_margin DESC
LIMIT 10
