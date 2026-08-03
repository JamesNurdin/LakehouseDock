WITH ranked AS (
  SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    CASE WHEN SUM(sr.sr_net_loss) > SUM(cr.cr_net_loss) THEN 'Store higher' ELSE 'Catalog higher' END AS loss_comparison,
    ld.avg_item_discount,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss)) DESC) AS rnk
  FROM store s
  JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
  JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_time_sk = t.t_time_sk
  JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  JOIN warehouse wh_cr ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse wh_ws ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
  JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  CROSS JOIN LATERAL (
        SELECT avg(ws2.ws_ext_discount_amt) AS avg_item_discount
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
      ) AS ld
  WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 100
      )
    AND i.i_item_sk IN (
        SELECT cr3.cr_item_sk FROM catalog_returns cr3 WHERE cr3.cr_net_loss > 0
        INTERSECT
        SELECT sr3.sr_item_sk FROM store_returns sr3 WHERE sr3.sr_net_loss > 0
      )
  GROUP BY s.s_store_name, s.s_city, s.s_state, ld.avg_item_discount
)
SELECT
  s_store_name,
  s_city,
  total_store_loss,
  total_catalog_loss,
  loss_comparison,
  avg_item_discount
FROM ranked
WHERE rnk <= 5
ORDER BY total_store_loss DESC
LIMIT 100
