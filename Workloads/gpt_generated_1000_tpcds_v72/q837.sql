WITH base_a AS (
  SELECT
    s.s_store_name,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    w.w_city,
    wp.wp_type,
    COALESCE(r.r_reason_desc, r_web.r_reason_desc) AS reason_desc,
    SUM(cs.cs_net_paid) AS sum_catalog_net_paid,
    SUM(ss.ss_net_paid) AS sum_store_net_paid,
    SUM(ws.ws_net_paid) AS sum_web_net_paid,
    SUM(cs.cs_net_profit) AS sum_catalog_net_profit,
    SUM(ss.ss_net_profit) AS sum_store_net_profit,
    SUM(ws.ws_net_profit) AS sum_web_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS cnt_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS cnt_store_orders,
    COUNT(DISTINCT ws.ws_order_number) AS cnt_web_orders
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
  WHERE i.i_brand = 'Brand#12'
    AND w.w_state = 'CA'
    AND wp.wp_max_ad_count >= 3
    AND i.i_rec_start_date > DATE '2001-01-01'
  GROUP BY
    s.s_store_name,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    w.w_city,
    wp.wp_type,
    COALESCE(r.r_reason_desc, r_web.r_reason_desc)
),
base_b AS (
  SELECT
    s.s_store_name,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    w.w_city,
    wp.wp_type,
    COALESCE(r.r_reason_desc, r_web.r_reason_desc) AS reason_desc,
    SUM(cs.cs_net_paid) AS sum_catalog_net_paid,
    SUM(ss.ss_net_paid) AS sum_store_net_paid,
    SUM(ws.ws_net_paid) AS sum_web_net_paid,
    SUM(cs.cs_net_profit) AS sum_catalog_net_profit,
    SUM(ss.ss_net_profit) AS sum_store_net_profit,
    SUM(ws.ws_net_profit) AS sum_web_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS cnt_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS cnt_store_orders,
    COUNT(DISTINCT ws.ws_order_number) AS cnt_web_orders
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
  WHERE i.i_brand = 'Brand#34'
    AND w.w_state = 'TX'
    AND wp.wp_image_count <= 2
    AND i.i_rec_start_date < DATE '2000-01-01'
  GROUP BY
    s.s_store_name,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    w.w_city,
    wp.wp_type,
    COALESCE(r.r_reason_desc, r_web.r_reason_desc)
)
SELECT *
FROM base_a
UNION ALL
SELECT *
FROM base_b
ORDER BY (sum_catalog_net_paid + sum_store_net_paid + sum_web_net_paid) DESC
LIMIT 100
