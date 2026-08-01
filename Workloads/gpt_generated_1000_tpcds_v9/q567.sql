WITH base_date AS (
    SELECT d_date_sk
    FROM tpcds.date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1220
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ss.ss_net_paid)                         AS total_store_net_paid,
    SUM(ws.ws_net_paid)                         AS total_web_net_paid,
    SUM(COALESCE(cr.cr_return_amount, 0))       AS total_catalog_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0))          AS total_web_return_amount,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
    AVG(i.i_current_price)                      AS avg_item_price,
    COUNT(DISTINCT ss.ss_customer_sk)           AS store_customer_cnt,
    COUNT(DISTINCT ws.ws_bill_customer_sk)      AS web_customer_cnt,
    COALESCE(cc.cc_name, 'No Call Center')      AS call_center_name,
    COALESCE(cp.cp_description, 'No Catalog Page') AS catalog_page_desc,
    COALESCE(sm_cr.sm_type, 'Unknown')          AS ship_mode_type,
    COALESCE(p.p_promo_name, 'No Promo')        AS promo_name,
    COALESCE(wp.wp_url, 'No URL')               AS web_page_url
FROM tpcds.item i
JOIN tpcds.store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t_ss
  ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN tpcds.household_demographics hd_store
  ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
LEFT JOIN tpcds.promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN tpcds.household_demographics hd_web_bill
  ON ws.ws_bill_hdemo_sk = hd_web_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_web_ship
  ON ws.ws_ship_hdemo_sk = hd_web_ship.hd_demo_sk
JOIN tpcds.ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN tpcds.catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN tpcds.ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d_sold.d_date_sk
 AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN tpcds.household_demographics hd_wr_refunded
  ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
LEFT JOIN tpcds.household_demographics hd_wr_returning
  ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
LEFT JOIN tpcds.web_page wp_wr
  ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
LEFT JOIN tpcds.inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year = 2001
    AND t_ss.t_hour BETWEEN 10 AND 16
    AND i.i_current_price > 30.00
    AND i.i_manager_id IN (34, 21)
    AND p.p_discount_active = 'Y'
    AND cc.cc_state = 'CA'
    AND sm_cr.sm_type = 'AIR'
    AND wp.wp_link_count >= 10
    AND inv.inv_quantity_on_hand > 0
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cc.cc_name,
    cp.cp_description,
    sm_cr.sm_type,
    p.p_promo_name,
    wp.wp_url
ORDER BY
    total_store_net_paid DESC,
    total_web_net_paid DESC
LIMIT 100
