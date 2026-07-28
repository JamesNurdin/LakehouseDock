WITH base AS (
  SELECT
    cr.cr_refunded_customer_sk                AS cust_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    dr.d_year,
    cr.cr_net_loss,
    ws.ws_net_profit,
    inv.inv_quantity_on_hand,
    cd.cd_gender
  FROM catalog_returns cr
  JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   AND sm.sm_type = 'AIR'
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = dr.d_date_sk
   AND inv.inv_quantity_on_hand > 0
  LEFT JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
   AND s.s_tax_percentage < 0.06
  LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = dr.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   AND cd.cd_gender = 'M'
  WHERE dr.d_year = 2002
    AND i.i_current_price > 50
),
agg AS (
  SELECT
    cust_sk,
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    SUM(cr_net_loss)          AS total_return_loss,
    SUM(ws_net_profit)        AS total_web_profit,
    SUM(inv_quantity_on_hand) AS total_inventory
  FROM base
  GROUP BY cust_sk, c_customer_id, c_first_name, c_last_name, d_year
)
SELECT
  cust_sk,
  c_customer_id,
  c_first_name,
  c_last_name,
  d_year,
  total_return_loss,
  total_web_profit,
  total_inventory,
  RANK() OVER (PARTITION BY d_year ORDER BY total_return_loss DESC) AS loss_rank
FROM agg
ORDER BY loss_rank
LIMIT 100
