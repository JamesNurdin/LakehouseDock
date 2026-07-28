SELECT
  d.d_year,
  r.r_reason_desc,
  hd.hd_buy_potential,
  SUM(cs.cs_net_paid)               AS total_catalog_sales_net_paid,
  SUM(sr.sr_net_loss)               AS total_store_returns_net_loss,
  SUM(cr.cr_net_loss)               AS total_catalog_returns_net_loss,
  SUM(ws.ws_net_paid)               AS total_web_sales_net_paid,
  COUNT(DISTINCT c.c_customer_id)   AS unique_customers
FROM
  date_dim d
  -- Store Sales and its related dimensions
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p_store
    ON ss.ss_promo_sk = p_store.p_promo_sk
  -- Store Returns linked to Store Sales
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk       = ss.ss_item_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  -- Catalog Sales and its related dimensions
  JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p_cat
    ON cs.cs_promo_sk = p_cat.p_promo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  -- Catalog Returns linked to Catalog Sales
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk      = cs.cs_item_sk
  -- Inventory linked via Warehouse and Date
  JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
   AND i.inv_date_sk      = d.d_date_sk
  -- Web Sales and its related dimensions
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p_web
    ON ws.ws_promo_sk = p_web.p_promo_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
WHERE
  d.d_year = 2001
  AND hd.hd_income_band_sk = 11
  AND r.r_reason_desc = 'Wrong size'
  AND cs.cs_quantity > 5
GROUP BY
  ROLLUP (d.d_year, r.r_reason_desc, hd.hd_buy_potential)
ORDER BY
  d.d_year ASC,
  r.r_reason_desc ASC,
  hd.hd_buy_potential ASC
