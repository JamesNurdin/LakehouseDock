WITH base AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_net_paid,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    p.p_promo_id,
    sm.sm_ship_mode_id,
    wp.wp_url,
    wsite.web_name,
    cust_bill.c_customer_id,
    cust_bill.c_first_name,
    cust_bill.c_last_name,
    cd_bill.cd_gender,
    hd_bill.hd_buy_potential,
    ib.ib_upper_bound,
    inv.inv_quantity_on_hand,
    cs.cs_quantity AS catalog_quantity,
    ss.ss_quantity AS store_quantity,
    wr.wr_return_quantity,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
  JOIN customer cust_refund ON wr.wr_refunded_customer_sk = cust_refund.c_customer_sk
  JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
  JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
  JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
  WHERE i.i_brand = 'Brand#23'
    AND ib.ib_upper_bound >= 120000
    AND ws.ws_sold_date_sk >= 2451910
)
SELECT
  ws_sold_date_sk,
  c_customer_id,
  c_first_name,
  c_last_name,
  i_brand,
  i_category,
  promo_active_flag,
  total_paid,
  DENSE_RANK() OVER (ORDER BY total_paid DESC) AS customer_rank,
  SUM(ws_net_paid) OVER (PARTITION BY i_brand ORDER BY ws_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS brand_rolling_sum
FROM (
  SELECT
    ws_sold_date_sk,
    c_customer_id,
    c_first_name,
    c_last_name,
    i_brand,
    i_category,
    promo_active_flag,
    ws_net_paid,
    SUM(ws_net_paid) OVER (PARTITION BY c_customer_id) AS total_paid
  FROM base
) t
ORDER BY customer_rank
LIMIT 100
