SELECT
  i.i_category                AS category,
  cd.cd_gender                AS gender,
  d_ss.d_year                 AS sales_year,
  SUM(ss.ss_net_paid)        AS store_sales_net_paid,
  SUM(cs.cs_net_paid)        AS catalog_sales_net_paid,
  SUM(cr.cr_net_loss)        AS catalog_return_loss,
  SUM(wr.wr_net_loss)        AS web_return_loss,
  SUM(inv.inv_quantity_on_hand) AS inventory_on_hand
FROM store_sales ss
JOIN date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk

-- Catalog sales path
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs
  ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN call_center cc_cs
  ON cs.cs_call_center_sk = cc_cs.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk

-- Catalog returns path
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk

-- Web returns path
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk

-- Inventory path
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk

WHERE d_ss.d_year = 2001
GROUP BY i.i_category, cd.cd_gender, d_ss.d_year
ORDER BY store_sales_net_paid DESC
LIMIT 100
