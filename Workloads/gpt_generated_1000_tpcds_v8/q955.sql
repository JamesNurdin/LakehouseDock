WITH
  base AS (
    SELECT
      cc.cc_name,
      cc.cc_state,
      cp.cp_catalog_page_id,
      i.i_item_sk,
      i.i_category,
      i.i_product_name,
      sm.sm_ship_mode_sk,
      sm.sm_carrier,
      sm.sm_type,
      t.t_hour,
      c.c_customer_sk,
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_ext_sales_price,
      ws.ws_net_paid,
      sr.sr_net_loss,
      cr.cr_return_amount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
          AND sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_hdemo_sk = hd.hd_demo_sk
          AND sr.sr_addr_sk = ca.ca_address_sk
          AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
          AND cr.cr_refunded_customer_sk = c.c_customer_sk
          AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
          AND cr.cr_refunded_addr_sk = ca.ca_address_sk
          AND cr.cr_returned_time_sk = t.t_time_sk
          AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
          AND ws.ws_bill_customer_sk = c.c_customer_sk
          AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
          AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
          AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_carrier = 'FEDEX'
      AND i.i_category = 'Electronics'
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 500
      )
  ),
  common_orders AS (
    SELECT cs_order_number FROM catalog_sales
    INTERSECT
    SELECT ws_order_number FROM web_sales
  ),
  carrier_city_union AS (
    SELECT sm_carrier AS val FROM ship_mode
    UNION ALL
    SELECT web_city AS val FROM web_site
  ),
  cross_vals AS (
    SELECT d.sm_type, v.val
    FROM (SELECT DISTINCT sm_type FROM ship_mode) d
    CROSS JOIN (VALUES ROW(1), ROW(2)) AS v(val)
  ),
  item_avg AS (
    SELECT b.*, la.avg_item_price
    FROM base b
    CROSS JOIN LATERAL (
      SELECT AVG(cs2.cs_ext_sales_price) AS avg_item_price
      FROM catalog_sales cs2
      WHERE cs2.cs_item_sk = b.i_item_sk
    ) la
  )
SELECT
  ia.cc_name,
  ia.i_category,
  ia.sm_carrier,
  COUNT(DISTINCT ia.cs_order_number) AS order_cnt,
  SUM(ia.cs_net_paid) AS total_sales,
  AVG(ia.ws_net_paid) AS avg_web_sales,
  SUM(ia.sr_net_loss) AS total_store_loss,
  MAX(ia.cr_return_amount) AS max_return_amount,
  (SELECT COUNT(*) FROM carrier_city_union) AS union_cnt,
  cv.sm_type,
  cv.val AS cross_val,
  AVG(ia.avg_item_price) AS avg_price_per_item
FROM item_avg ia
JOIN common_orders co ON ia.cs_order_number = co.cs_order_number
LEFT JOIN cross_vals cv ON cv.sm_type = ia.sm_type
GROUP BY
  ia.cc_name,
  ia.i_category,
  ia.sm_carrier,
  cv.sm_type,
  cv.val
ORDER BY total_sales DESC
OFFSET 0
FETCH NEXT 100 ROWS ONLY
