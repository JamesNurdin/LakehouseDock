WITH data_1998 AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(inv.inv_quantity_on_hand) AS inventory_qty
  FROM date_dim d
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
  LEFT JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN item i3 ON cr.cr_item_sk = i3.i_item_sk
  LEFT JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
  LEFT JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN promotion p2 ON p2.p_item_sk = i.i_item_sk AND p2.p_start_date_sk = d.d_date_sk
  LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
  LEFT JOIN date_dim d_promo_start ON p2.p_start_date_sk = d_promo_start.d_date_sk
  LEFT JOIN date_dim d_promo_end ON p2.p_end_date_sk = d_promo_end.d_date_sk
  LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  WHERE d.d_year = 1998
  GROUP BY d.d_year, i.i_item_id, i.i_product_name
),

data_1999 AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(inv.inv_quantity_on_hand) AS inventory_qty
  FROM date_dim d
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
  LEFT JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN item i3 ON cr.cr_item_sk = i3.i_item_sk
  LEFT JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
  LEFT JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN promotion p2 ON p2.p_item_sk = i.i_item_sk AND p2.p_start_date_sk = d.d_date_sk
  LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
  LEFT JOIN date_dim d_promo_start ON p2.p_start_date_sk = d_promo_start.d_date_sk
  LEFT JOIN date_dim d_promo_end ON p2.p_end_date_sk = d_promo_end.d_date_sk
  LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  WHERE d.d_year = 1999
  GROUP BY d.d_year, i.i_item_id, i.i_product_name
)

SELECT
  combined.d_year,
  combined.i_item_id,
  combined.i_product_name,
  combined.web_sales_amount,
  combined.store_return_amount,
  combined.catalog_return_amount,
  combined.inventory_qty,
  ROW_NUMBER() OVER (PARTITION BY combined.i_item_id ORDER BY combined.web_sales_amount DESC) AS rn
FROM (
  SELECT *, '1998' AS src_year FROM data_1998
  UNION ALL
  SELECT *, '1999' AS src_year FROM data_1999
) AS combined
ORDER BY combined.web_sales_amount DESC
LIMIT 100
