WITH
  inventory_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  missing_sales_items AS (
    SELECT inv_item_sk
    FROM inventory_sample
    EXCEPT
    SELECT ws_item_sk
    FROM web_sales
  ),
  cross_data AS (
    SELECT r.r_reason_desc, v.num
    FROM reason r
    CROSS JOIN (VALUES (1), (2), (3)) AS v(num)
    WHERE r.r_reason_sk < 10
  ),
  joined_data AS (
    SELECT
      ws.ws_warehouse_sk,
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_order_number,
      cr.cr_return_amount,
      i.i_category,
      i.i_current_price,
      w.w_warehouse_name,
      w.w_state,
      cc.cc_name,
      cp.cp_department,
      sm.sm_type,
      r.r_reason_desc,
      p.p_promo_name,
      ca.ca_state,
      td.t_hour,
      ws_site.web_name,
      -- correlated scalar subquery for max price in the same category
      (SELECT MAX(i2.i_current_price)
       FROM item i2
       WHERE i2.i_category = i.i_category) AS max_price_in_category,
      lr.return_cnt,
      cd.num AS cross_num
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
                           AND cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS return_cnt
      FROM catalog_returns cr3
      WHERE cr3.cr_item_sk = i.i_item_sk
        AND cr3.cr_warehouse_sk = w.w_warehouse_sk
    ) lr ON true
    LEFT JOIN cross_data cd ON cd.r_reason_desc = r.r_reason_desc
    WHERE w.w_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND td.t_hour BETWEEN 8 AND 12
      AND i.i_rec_start_date >= DATE '1998-01-01'
      AND p.p_discount_active = 'Y'
      AND ws_site.web_class = 'A'
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 100
      )
      AND i.i_item_sk NOT IN (SELECT inv_item_sk FROM missing_sales_items)
  )
SELECT
  w_warehouse_name,
  i_category,
  cc_name,
  cp_department,
  sm_type,
  r_reason_desc,
  ca_state,
  COUNT(DISTINCT ws_order_number) AS order_cnt,
  SUM(ws_net_paid) AS total_sales,
  SUM(cr_return_amount) AS total_returns,
  AVG(i_current_price) AS avg_price,
  MAX(max_price_in_category) AS category_max_price,
  SUM(return_cnt) AS total_return_events,
  SUM(cross_num) AS cross_num_sum,
  MAX(web_name) AS website_name
FROM joined_data
GROUP BY
  w_warehouse_name,
  i_category,
  cc_name,
  cp_department,
  sm_type,
  r_reason_desc,
  ca_state
ORDER BY total_sales DESC
LIMIT 100
