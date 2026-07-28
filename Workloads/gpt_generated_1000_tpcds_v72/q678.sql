WITH base AS (
  SELECT
    s.s_store_id,
    d.d_year,
    i.i_brand,
    c.c_customer_id,
    cs.cs_quantity,
    cs.cs_net_paid,
    ws.ws_net_paid
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN store_sales ss ON ss.ss_ticket_number = cs.cs_order_number
    AND ss.ss_item_sk = cs.cs_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
  JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  WHERE d.d_year = 1999
    AND s.s_state = 'CA'
    AND i.i_brand = 'Brand#23'
    AND p.p_discount_active = 'Y'
),
aggregated AS (
  SELECT
    b.s_store_id,
    b.d_year,
    b.i_brand,
    COUNT(DISTINCT b.c_customer_id) AS distinct_customers,
    SUM(b.cs_net_paid) AS total_net_paid,
    AVG(b.ws_net_paid) AS avg_web_net_paid,
    MIN(b.cs_quantity) AS min_quantity,
    MAX(b.cs_quantity) AS max_quantity
  FROM base b
  GROUP BY b.s_store_id, b.d_year, b.i_brand
)
SELECT
  a.s_store_id,
  a.d_year,
  a.i_brand,
  a.distinct_customers,
  a.total_net_paid,
  a.avg_web_net_paid,
  a.min_quantity,
  a.max_quantity,
  ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_paid DESC) AS store_sales_rank
FROM aggregated a
ORDER BY a.total_net_paid DESC
LIMIT 100
