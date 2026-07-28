WITH base AS (
  SELECT
    d.d_year AS d_year,
    i.i_category AS i_category,
    ss.ss_net_paid AS store_net_paid,
    ws.ws_net_paid AS web_net_paid,
    cs.cs_net_paid AS catalog_net_paid
  FROM date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                         AND cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_item_sk = i.i_item_sk
  LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                          AND sm.sm_code IN ('AIR','SEA')
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = i.i_item_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                       AND inv.inv_item_sk = i.i_item_sk
                       AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
    AND ws.ws_net_paid > 1000
)
SELECT
  d_year,
  i_category,
  SUM(store_net_paid)   AS total_store_net,
  SUM(web_net_paid)     AS total_web_net,
  SUM(catalog_net_paid) AS total_catalog_net,
  (SUM(store_net_paid) + SUM(web_net_paid) + SUM(catalog_net_paid)) / 3.0 AS avg_total_net
FROM base
GROUP BY d_year, i_category
ORDER BY total_store_net DESC
LIMIT 100
