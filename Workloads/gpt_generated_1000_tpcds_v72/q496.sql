WITH sales_summary AS (
  SELECT
    s.s_store_id,
    wsite.web_site_id,
    i.i_category,
    d_sold.d_year,
    cc.cc_name,
    cp.cp_catalog_page_number,
    sm.sm_type AS ship_mode_type,
    wwh.w_warehouse_name,
    cd.cd_gender,
    SUM(ss.ss_net_paid) AS store_sales_net,
    SUM(cs.cs_net_paid) AS catalog_sales_net,
    SUM(cr.cr_net_loss) AS catalog_returns_loss,
    SUM(ws.ws_net_paid) AS web_sales_net,
    SUM(wr.wr_net_loss) AS web_returns_loss,
    COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS inventory_on_hand
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_sales cs
    ON ss.ss_item_sk = cs.cs_item_sk
   AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
  LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse wwh
    ON cs.cs_warehouse_sk = wwh.w_warehouse_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
  LEFT JOIN web_sales ws
    ON ss.ss_item_sk = ws.ws_item_sk
   AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
  LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
  LEFT JOIN inventory inv
    ON ss.ss_item_sk = inv.inv_item_sk
   AND d_sold.d_date_sk = inv.inv_date_sk
  WHERE d_sold.d_year = 2001
  GROUP BY
    s.s_store_id,
    wsite.web_site_id,
    i.i_category,
    d_sold.d_year,
    cc.cc_name,
    cp.cp_catalog_page_number,
    sm.sm_type,
    wwh.w_warehouse_name,
    cd.cd_gender
)
SELECT
  s_store_id,
  web_site_id,
  i_category,
  d_year,
  cc_name,
  cp_catalog_page_number,
  ship_mode_type,
  w_warehouse_name,
  cd_gender,
  store_sales_net,
  catalog_sales_net,
  catalog_returns_loss,
  web_sales_net,
  web_returns_loss,
  inventory_on_hand
FROM sales_summary
ORDER BY store_sales_net DESC
LIMIT 100
