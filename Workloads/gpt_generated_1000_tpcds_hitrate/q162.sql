WITH
  d_sales AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2020
  ),
  d_ret AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2020
  ),
  inv_detail AS (
    SELECT i.inv_item_sk,
           i.inv_quantity_on_hand,
           i.inv_date_sk,
           i.inv_warehouse_sk,
           d_inv.d_year,
           w_inv.w_warehouse_name,
           w_inv.w_warehouse_sk
    FROM inventory i
    JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE d_inv.d_year = 2020
  ),
  promo_channels AS (
    SELECT p.p_promo_sk,
           split(p.p_channel_details, ',') AS channels,
           p.p_promo_name
    FROM promotion p
  ),
  promo_unnest AS (
    SELECT pc.p_promo_sk,
           trim(ch) AS channel,
           pc.p_promo_name
    FROM promo_channels pc
    CROSS JOIN UNNEST(pc.channels) AS t(ch)
  ),
  intersect_customers AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    WHERE ws.ws_quantity > 0
    INTERSECT
    SELECT cr.cr_refunded_customer_sk
    FROM catalog_returns cr
    JOIN d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE cr.cr_return_quantity > 0
  )
SELECT
  ic.cust_sk,
  c.c_first_name,
  c.c_last_name,
  d_sales.d_year,
  sm.sm_code,
  w.w_warehouse_name,
  ws.ws_net_profit,
  inv.inv_quantity_on_hand,
  pu.channel,
  pu.p_promo_name
FROM intersect_customers ic
JOIN customer c                     ON ic.cust_sk = c.c_customer_sk
JOIN web_sales ws                    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN d_sales d_sales                 ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN ship_mode sm                    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w                     ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p                     ON ws.ws_promo_sk = p.p_promo_sk
JOIN promo_unnest pu                 ON pu.p_promo_sk = p.p_promo_sk
JOIN inv_detail inv                  ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE pu.channel = 'EMAIL'
LIMIT 100
