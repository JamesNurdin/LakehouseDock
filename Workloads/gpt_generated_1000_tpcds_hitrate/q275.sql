WITH
  cs_data AS (
    SELECT
      cs.cs_order_number,
      d.d_year,
      cs.cs_net_paid,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      i.i_product_name,
      p.p_promo_name,
      sm.sm_type,
      w.w_warehouse_name,
      cc.cc_name,
      cp.cp_department,
      wp.wp_url,
      td.t_meal_time
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND c.c_birth_month = 5
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND cc.cc_state = 'CA'
  ),
  ws_data AS (
    SELECT
      ws.ws_order_number,
      d2.d_year,
      ws.ws_net_paid,
      c2.c_customer_sk,
      c2.c_first_name,
      c2.c_last_name,
      i2.i_product_name,
      p2.p_promo_name,
      sm2.sm_type,
      w2.w_warehouse_name,
      wp2.wp_type,
      wp2.wp_char_count
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN web_page wp2 ON ws.ws_web_page_sk = wp2.wp_web_page_sk
    WHERE d2.d_year = 2001
      AND c2.c_preferred_cust_flag = 'Y'
      AND wp2.wp_type = 'order'
      AND wp2.wp_char_count > 2000
      AND sm2.sm_type = 'AIR'
      AND w2.w_state = 'CA'
  ),
  intersect_orders AS (
    SELECT cs_order_number FROM cs_data
    INTERSECT
    SELECT ws_order_number FROM ws_data
  ),
  final_data AS (
    SELECT
      cs.cs_order_number,
      cs.c_customer_sk,
      cs.c_first_name,
      cs.c_last_name,
      cs.i_product_name,
      cs.cs_net_paid,
      cs.d_year,
      cs.cc_name,
      cs.cp_department,
      cs.sm_type,
      cs.w_warehouse_name,
      cs.wp_url,
      ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.cs_net_paid DESC) AS sales_rank
    FROM cs_data cs
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
      AND EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_return_quantity > 0
      )
  ),
  url_parts AS (
    SELECT
      fd.cs_order_number,
      fd.c_first_name,
      fd.c_last_name,
      fd.i_product_name,
      fd.cs_net_paid,
      fd.sales_rank,
      fd.cc_name,
      fd.cp_department,
      fd.sm_type,
      fd.w_warehouse_name,
      part AS url_part
    FROM final_data fd
    LEFT JOIN UNNEST(split(fd.wp_url, '/')) AS t(part) ON true
    WHERE fd.sales_rank <= 10
  )
SELECT
  up.cs_order_number,
  up.c_first_name,
  up.c_last_name,
  up.i_product_name,
  up.cs_net_paid,
  up.sales_rank,
  up.cc_name,
  up.cp_department,
  up.sm_type,
  up.w_warehouse_name,
  up.url_part,
  (SELECT AVG(cs_net_paid) FROM cs_data) AS avg_sales_amount
FROM url_parts up
ORDER BY up.cs_net_paid DESC
LIMIT 100
