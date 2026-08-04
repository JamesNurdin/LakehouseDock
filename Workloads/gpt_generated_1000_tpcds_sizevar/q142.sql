SELECT
  d.d_year,
  i.i_category,
  ca.ca_state,
  p.p_promo_name,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
  AVG(ss.ss_ext_discount_amt) AS avg_discount,
  MAX(cr.cr_net_loss) AS max_return_loss,
  MIN(wr.wr_net_loss) AS min_web_loss
FROM
  tpcds.store_sales ss
  JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND ca.ca_state = 'CA'
  AND p.p_promo_name = 'Christmas Promo'
  AND ss.ss_quantity > (
    SELECT AVG(ss2.ss_quantity)
    FROM tpcds.store_sales ss2
    WHERE ss2.ss_sold_date_sk = d.d_date_sk
  )
  AND EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr2
    WHERE wr2.wr_item_sk = i.i_item_sk
      AND wr2.wr_net_loss > 1000
  )
GROUP BY
  d.d_year,
  i.i_category,
  ca.ca_state,
  p.p_promo_name
ORDER BY
  total_sales DESC
LIMIT 100
