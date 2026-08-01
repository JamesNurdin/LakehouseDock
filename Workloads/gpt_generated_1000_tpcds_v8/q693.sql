WITH
  store_items AS (
    SELECT ss_item_sk
    FROM store_sales
  ),
  web_items AS (
    SELECT ws_item_sk
    FROM web_sales
  ),
  common_items AS (
    SELECT ss_item_sk AS item_sk FROM store_items
    INTERSECT
    SELECT ws_item_sk FROM web_items
  ),
  sales AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ss.ss_cdemo_sk,
      ss.ss_addr_sk
    FROM store_sales ss
    WHERE ss.ss_item_sk IN (SELECT item_sk FROM common_items)
  ),
  web AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ship_date_sk,
      ws.ws_item_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      ws.ws_promo_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_bill_addr_sk,
      ws.ws_ship_cdemo_sk,
      ws.ws_ship_addr_sk
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (5)
    WHERE ws.ws_item_sk IN (SELECT item_sk FROM common_items)
  )
SELECT
  d_sales.d_year AS sales_year,
  s.s_store_name,
  i.i_product_name,
  p.p_promo_name,
  SUM(COALESCE(sales.ss_quantity, 0)) AS total_store_qty,
  SUM(COALESCE(web.ws_quantity, 0)) AS total_web_qty,
  SUM(COALESCE(sales.ss_net_profit, 0)) + SUM(COALESCE(web.ws_net_profit, 0)) AS total_profit,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_amount,
  SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss
FROM
  sales
  FULL OUTER JOIN web
    ON sales.ss_item_sk = web.ws_item_sk
   AND sales.ss_sold_date_sk = web.ws_sold_date_sk
  JOIN date_dim d_sales
    ON sales.ss_sold_date_sk = d_sales.d_date_sk
  JOIN date_dim d_web_sold
    ON web.ws_sold_date_sk = d_web_sold.d_date_sk
  JOIN date_dim d_web_ship
    ON web.ws_ship_date_sk = d_web_ship.d_date_sk
  JOIN item i
    ON sales.ss_item_sk = i.i_item_sk
   AND web.ws_item_sk = i.i_item_sk
  JOIN store s
    ON sales.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON sales.ss_promo_sk = p.p_promo_sk
   AND web.ws_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d_sales.d_date_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sales.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
   OR web.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
   OR cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_address ca_store
    ON sales.ss_addr_sk = ca_store.ca_address_sk
  LEFT JOIN customer_address ca_web_bill
    ON web.ws_bill_addr_sk = ca_web_bill.ca_address_sk
  LEFT JOIN customer_demographics cd_store
    ON sales.ss_cdemo_sk = cd_store.cd_demo_sk
  LEFT JOIN customer_demographics cd_web_bill
    ON web.ws_bill_cdemo_sk = cd_web_bill.cd_demo_sk
WHERE
  d_sales.d_year = 2002
GROUP BY
  d_sales.d_year,
  s.s_store_name,
  i.i_product_name,
  p.p_promo_name
ORDER BY
  total_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
