WITH base AS (
  SELECT
    c.c_customer_id AS c_customer_id,
    i.i_category AS i_category,
    i.i_manufact AS i_manufact,
    SUM(cs.cs_net_paid) AS cs_total,
    SUM(ss.ss_net_paid) AS ss_total,
    SUM(ws.ws_net_paid) AS ws_total,
    SUM(sr.sr_return_amt) AS sr_total_return,
    SUM(cr.cr_return_amount) AS cr_total_return,
    SUM(inv.inv_quantity_on_hand) AS inv_qty,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_item_sk = i.i_item_sk
   AND sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = t.t_time_sk
   AND cr.cr_item_sk = i.i_item_sk
   AND cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
   AND wp.wp_customer_sk = c.c_customer_sk
  WHERE t.t_minute IN (4, 10, 17)
    AND t.t_meal_time = 'lunch'
    AND i.i_category_id = 8
    AND i.i_manufact_id = 338
    AND c.c_birth_year BETWEEN 1950 AND 1960
    AND hd.hd_vehicle_count >= 2
    AND wp.wp_image_count >= 5
    AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cs.cs_order_number
        AND cr2.cr_return_amount > 100
    )
  GROUP BY c.c_customer_id, i.i_category, i.i_manufact
)
SELECT *
FROM (
  SELECT
    c_customer_id,
    i_category,
    i_manufact,
    (cs_total + ss_total + ws_total) - (sr_total_return + cr_total_return) AS net_flow,
    inv_qty,
    order_cnt
  FROM base
  WHERE inv_qty > 0

  UNION DISTINCT

  SELECT
    c_customer_id,
    i_category,
    i_manufact,
    (cs_total + ss_total + ws_total) - (sr_total_return + cr_total_return) AS net_flow,
    inv_qty,
    order_cnt
  FROM base
  WHERE order_cnt >= 5
) AS u
WHERE net_flow > (
  SELECT AVG(cs_total + ss_total + ws_total) FROM base
)
ORDER BY net_flow DESC
OFFSET 10 LIMIT 20
