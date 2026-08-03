WITH
  -- central web sales fact joined to many dimensions (star topology)
  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ship_date_sk,
      ws.ws_item_sk,
      ws.ws_net_paid_inc_tax,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      d_sold.d_year            AS sold_year,
      d_ship.d_year            AS ship_year,
      c_bill.c_customer_id     AS bill_customer_id,
      c_ship.c_customer_id     AS ship_customer_id,
      cd_bill.cd_gender        AS bill_gender,
      cd_ship.cd_gender        AS ship_gender,
      hd_bill.hd_buy_potential AS bill_buy_potential,
      hd_ship.hd_buy_potential AS ship_buy_potential,
      wp.wp_url,
      we.web_name,
      w.w_warehouse_name
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill
      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
      ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill
      ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill
      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
  ),

  -- inventory linked to warehouse and date (FULL OUTER JOIN required)
  inv AS (
    SELECT
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      w.w_warehouse_name,
      d.d_year AS inv_year
    FROM inventory i
    FULL OUTER JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
      ON i.inv_date_sk = d.d_date_sk
  ),

  -- catalog returns with their supporting dimensions
  cat_ret AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cp.cp_catalog_number,
      r.r_reason_desc,
      d.d_year AS ret_year,
      w.w_warehouse_name
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
  ),

  -- store returns plus the related store sales (adds store_sales table)
  str_ret AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      r.r_reason_desc      AS store_return_reason,
      d.d_year             AS ret_year,
      c.c_customer_id,
      ss.ss_net_paid       AS store_sale_net_paid
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store_sales ss
      ON sr.sr_ticket_number = ss.ss_ticket_number
  ),

  -- web returns linked to the original web sales order
  web_ret AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      r.r_reason_desc      AS web_return_reason,
      d.d_year             AS ret_year,
      wp.wp_url
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
  ),

  -- key sets for set operations
  intersect_keys AS (
    SELECT ws_order_number FROM ws
    INTERSECT
    SELECT wr_order_number FROM web_ret
  ),

  except_keys AS (
    SELECT ws_order_number FROM ws
    EXCEPT
    SELECT wr_order_number FROM web_ret
  )

SELECT
  DISTINCT
  ws.ws_order_number,
  ws.sold_year,
  ws.ship_year,
  ws.bill_customer_id,
  ws.ship_customer_id,
  ws.ws_net_paid_inc_tax,
  inv.inv_quantity_on_hand,
  cat_ret.cp_catalog_number,
  cat_ret.r_reason_desc               AS catalog_return_reason,
  str_ret.store_return_reason,
  web_ret.web_return_reason,
  CASE
    WHEN ws.ws_order_number IN (SELECT ws_order_number FROM intersect_keys) THEN 'BothSaleAndReturn'
    WHEN ws.ws_order_number IN (SELECT ws_order_number FROM except_keys)   THEN 'SaleOnly'
    ELSE 'Other'
  END                                 AS order_status
FROM ws
LEFT JOIN inv
  ON ws.ws_item_sk = inv.inv_item_sk
LEFT JOIN cat_ret
  ON ws.ws_order_number = cat_ret.cr_order_number
LEFT JOIN str_ret
  ON ws.ws_order_number = str_ret.sr_ticket_number
LEFT JOIN web_ret
  ON ws.ws_order_number = web_ret.wr_order_number
WHERE ws.ws_net_paid_inc_tax > 1000
  AND ws.sold_year BETWEEN 2001 AND 2002
ORDER BY ws.ws_net_paid_inc_tax DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
