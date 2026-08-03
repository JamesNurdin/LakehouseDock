WITH store_data AS (
  SELECT
    td.t_time_sk AS time_sk,
    i.i_item_sk AS item_sk,
    s.s_store_sk AS store_sk,
    p.p_promo_sk AS promo_sk,
    i.i_category AS category,
    ib.ib_lower_bound AS income_lower,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(ss.ss_quantity) AS store_sales_qty,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amount,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS store_return_qty,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  WHERE i.i_current_price > 100
    AND s.s_state = 'CA'
    AND ib.ib_upper_bound <= 200000
  GROUP BY
    td.t_time_sk,
    i.i_item_sk,
    s.s_store_sk,
    p.p_promo_sk,
    i.i_category,
    ib.ib_lower_bound
),
web_data AS (
  SELECT
    td.t_time_sk AS time_sk,
    i.i_item_sk AS item_sk,
    ws.ws_web_site_sk AS web_site_sk,
    ws.ws_warehouse_sk AS warehouse_sk,
    ws.ws_web_page_sk AS web_page_sk,
    ws.ws_promo_sk AS promo_sk,
    i.i_category AS category,
    ib.ib_lower_bound AS income_lower,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(ws.ws_quantity) AS web_sales_qty,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS web_return_qty,
    COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
  FROM web_sales ws
  JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  WHERE w.w_state = 'GA'
    AND we.web_country = 'United States'
    AND i.i_current_price > 150
  GROUP BY
    td.t_time_sk,
    i.i_item_sk,
    ws.ws_web_site_sk,
    ws.ws_warehouse_sk,
    ws.ws_web_page_sk,
    ws.ws_promo_sk,
    i.i_category,
    ib.ib_lower_bound
)
SELECT
  sd.time_sk,
  sd.item_sk,
  sd.store_sk,
  wd.web_site_sk,
  sd.category,
  sd.income_lower,
  sd.store_sales_amount,
  wd.web_sales_amount,
  (sd.store_sales_amount + wd.web_sales_amount) AS total_sales_amount,
  (sd.store_return_amount + wd.web_return_amount) AS total_return_amount,
  (sd.store_sales_amount + wd.web_sales_amount) - (sd.store_return_amount + wd.web_return_amount) AS net_sales,
  sd.store_txn_cnt,
  wd.web_txn_cnt
FROM store_data sd
JOIN web_data wd
  ON sd.time_sk = wd.time_sk
 AND sd.item_sk = wd.item_sk
ORDER BY total_sales_amount DESC
LIMIT 100
