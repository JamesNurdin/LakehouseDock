WITH filtered_items AS (
   SELECT i.*
   FROM item i
   WHERE i.i_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 0
   )
),
item_unnest AS (
   SELECT i.i_item_sk,
          i.i_item_id,
          i.i_product_name,
          val AS extra_val
   FROM filtered_items i
   CROSS JOIN UNNEST(array[i.i_item_sk, i.i_item_sk + 10]) AS t(val)
),
promo_latest AS (
   SELECT p.p_item_sk,
          p.p_promo_id,
          ROW_NUMBER() OVER (PARTITION BY p.p_item_sk ORDER BY p.p_start_date_sk DESC) AS rn
   FROM promotion p
),
promo_latest_one AS (
   SELECT p_item_sk, p_promo_id
   FROM promo_latest
   WHERE rn = 1
)
SELECT
   i.i_item_id,
   i.i_product_name,
   inv.inv_quantity_on_hand,
   p.p_promo_id AS promo_id,
   cr.cr_return_amount,
   sr.sr_return_quantity,
   wr.wr_return_amt,
   ws.ws_net_paid_inc_ship,
   SUM(ws.ws_net_paid_inc_ship) OVER (
        PARTITION BY i.i_item_id
        ORDER BY ws.ws_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS running_net_paid,
   lt.line_total,
   pl.p_promo_id AS latest_promo_id,
   p_full.p_promo_id AS full_outer_promo_id,
   i.extra_val
FROM item_unnest i
INNER JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
INNER JOIN promotion p ON p.p_item_sk = i.i_item_sk
INNER JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
INNER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
INNER JOIN (
    SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
) ws ON ws.ws_item_sk = i.i_item_sk
INNER JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
INNER JOIN household_demographics hd_cr_refund ON hd_cr_refund.hd_demo_sk = cr.cr_refunded_hdemo_sk
INNER JOIN household_demographics hd_cr_return ON hd_cr_return.hd_demo_sk = cr.cr_returning_hdemo_sk
INNER JOIN household_demographics hd_sr ON hd_sr.hd_demo_sk = sr.sr_hdemo_sk
INNER JOIN household_demographics hd_wr_refund ON hd_wr_refund.hd_demo_sk = wr.wr_refunded_hdemo_sk
INNER JOIN household_demographics hd_wr_return ON hd_wr_return.hd_demo_sk = wr.wr_returning_hdemo_sk
INNER JOIN household_demographics hd_ws_bill ON hd_ws_bill.hd_demo_sk = ws.ws_bill_hdemo_sk
INNER JOIN household_demographics hd_ws_ship ON hd_ws_ship.hd_demo_sk = ws.ws_ship_hdemo_sk
LEFT JOIN promo_latest_one pl ON pl.p_item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT ws.ws_quantity * ws.ws_sales_price AS line_total
) lt
FULL OUTER JOIN promotion p_full ON p_full.p_item_sk = i.i_item_sk
ORDER BY running_net_paid DESC
LIMIT 100
