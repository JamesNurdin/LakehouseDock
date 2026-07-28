WITH store_item_sales AS (
    SELECT
        ss_item_sk AS item_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit,
        COUNT(*) AS store_txn_cnt
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ss_ext_discount_amt < 1000
      AND ss_coupon_amt <> 0
      AND ss_ext_tax > 0
    GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cc.cc_state,
    cp.cp_department,
    SUM(sis.total_store_sales) AS store_sales_sum,
    SUM(ws.ws_ext_sales_price) AS web_sales_sum,
    SUM(wr.wr_return_amt) AS total_return_amount,
    CASE WHEN SUM(sis.total_store_sales) + SUM(ws.ws_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_category
FROM store_item_sales sis
JOIN item i
  ON i.i_item_sk = sis.item_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
  ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN reason r
  ON r.r_reason_sk = cr.cr_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_order_number = ws.ws_order_number
JOIN web_page wp
  ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN customer c
  ON c.c_customer_sk = cr.cr_refunded_customer_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = c.c_current_hdemo_sk
WHERE i.i_current_price > 50
  AND i.i_rec_start_date <= DATE '2023-01-01'
  AND i.i_rec_end_date >= DATE '2024-01-01'
  AND cc.cc_state = 'CA'
  AND cp.cp_type = 'PROMO'
  AND sm.sm_carrier = 'UPS'
  AND w.w_gmt_offset = -5.00
  AND r.r_reason_desc LIKE '%time%'
GROUP BY i.i_item_id, i.i_product_name, cc.cc_state, cp.cp_department
ORDER BY sales_category DESC, store_sales_sum DESC
LIMIT 100
