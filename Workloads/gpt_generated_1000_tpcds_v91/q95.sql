WITH union_sales AS (
  SELECT
    i.i_item_sk AS i_item_sk,
    i.i_category AS i_category,
    i.i_brand AS i_brand,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_quantity AS quantity_sold,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    COALESCE(inv.inv_quantity_on_hand, 0) AS inv_qty_on_hand,
    COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
    COALESCE(cr.cr_return_quantity, 0) AS catalog_return_quantity,
    sm.sm_type AS ship_mode_type,
    cd_sales.cd_gender AS customer_gender,
    hd_sales.hd_income_band_sk AS household_income_band,
    cd_refunded.cd_gender AS refunded_customer_gender,
    hd_refunded.hd_income_band_sk AS refunded_household_income_band
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
  JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
  LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND inv.inv_date_sk = ss.ss_sold_date_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
  LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
  LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
  LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450805 AND 2451200
  UNION
  SELECT
    i2.i_item_sk AS i_item_sk,
    i2.i_category AS i_category,
    i2.i_brand AS i_brand,
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_quantity AS quantity_sold,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    COALESCE(inv2.inv_quantity_on_hand, 0) AS inv_qty_on_hand,
    COALESCE(wr.wr_return_quantity, 0) AS return_quantity,
    0 AS catalog_return_quantity,
    sm1.sm_type AS ship_mode_type,
    cd_bill.cd_gender AS customer_gender,
    hd_bill.hd_income_band_sk AS household_income_band,
    cd_wr_refund.cd_gender AS refunded_customer_gender,
    hd_wr_refund.hd_income_band_sk AS refunded_household_income_band
  FROM web_sales ws
  JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN web_page wpage ON ws.ws_web_page_sk = wpage.wp_web_page_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN ship_mode sm1 ON ws.ws_ship_mode_sk = sm1.sm_ship_mode_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
  LEFT JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
  LEFT JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
  LEFT JOIN inventory inv2 ON i2.i_item_sk = inv2.inv_item_sk AND inv2.inv_date_sk = ws.ws_sold_date_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450805 AND 2451200
),
agg_sales AS (
  SELECT
    i_item_sk,
    i_category,
    i_brand,
    SUM(quantity_sold) AS total_quantity_sold,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(inv_qty_on_hand) AS total_inventory,
    SUM(return_quantity) AS total_return_quantity,
    SUM(catalog_return_quantity) AS total_catalog_return_quantity,
    COUNT(DISTINCT date_sk) AS active_days
  FROM union_sales
  WHERE EXISTS (
    SELECT 1 FROM store s_check
    WHERE s_check.s_store_id = 'Store_001' AND s_check.s_state = 'CA'
  )
  GROUP BY i_item_sk, i_category, i_brand
  HAVING SUM(net_profit) > 0
)
SELECT
  a.i_item_sk,
  a.i_category,
  a.i_brand,
  a.total_quantity_sold,
  a.total_net_paid,
  a.total_net_profit,
  a.total_inventory,
  a.total_return_quantity,
  a.total_catalog_return_quantity,
  a.active_days,
  ROW_NUMBER() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank,
  (SELECT MAX(inv_quantity_on_hand) FROM inventory) AS max_inventory_overall
FROM agg_sales a
ORDER BY a.total_net_profit DESC
LIMIT 100
