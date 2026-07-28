WITH
  base AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_net_paid,
      ws.ws_ext_tax,
      ws.ws_net_profit,
      ws.ws_order_number,
      ws.ws_web_site_sk,
      ws.ws_warehouse_sk,
      ws.ws_promo_sk,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_gmt_offset,
      p.p_promo_id,
      p.p_discount_active,
      c.c_customer_id,
      cr.cr_return_amount,
      i.inv_quantity_on_hand
    FROM web_sales ws
    INNER JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN web_site s
      ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
      AND cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
      ON i.inv_warehouse_sk = w.w_warehouse_sk
  ),
  agg1 AS (
    SELECT
      b.ws_web_site_sk,
      b.w_warehouse_sk,
      b.w_warehouse_name,
      b.p_promo_id,
      SUM(b.ws_net_paid)        AS total_net_paid,
      SUM(b.ws_ext_tax)         AS total_tax,
      AVG(b.ws_net_profit)      AS avg_profit,
      COUNT(DISTINCT b.ws_order_number) AS orders_cnt
    FROM base b
    WHERE b.ws_net_paid > 1000
      AND b.ws_ext_tax < 200
      AND b.w_gmt_offset = -6.00
      AND b.p_discount_active = 'Y'
      AND b.ws_sold_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY
      b.ws_web_site_sk,
      b.w_warehouse_sk,
      b.w_warehouse_name,
      b.p_promo_id
  )
SELECT
  a.ws_web_site_sk,
  a.w_warehouse_name,
  a.p_promo_id,
  a.total_net_paid,
  a.total_tax,
  a.avg_profit,
  a.orders_cnt,
  (SELECT MAX(cr_return_amount)
   FROM catalog_returns cr
   WHERE cr.cr_warehouse_sk = a.w_warehouse_sk) AS max_return_amount,
  RANK() OVER (ORDER BY a.total_net_paid DESC) AS revenue_rank
FROM agg1 a
WHERE a.total_net_paid > 5000
ORDER BY revenue_rank
LIMIT 100
