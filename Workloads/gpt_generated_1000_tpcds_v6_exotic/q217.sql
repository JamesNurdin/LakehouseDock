WITH catalog_ret AS (
   SELECT
      c.c_customer_id AS customer_id,
      cr.cr_return_amount AS return_amount,
      r.r_reason_desc AS reason_desc,
      'Catalog' AS channel
   FROM catalog_returns cr
   JOIN catalog_sales cs
     ON cr.cr_order_number = cs.cs_order_number
   JOIN customer c
     ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cr.cr_net_loss > 1000
     AND cs.cs_item_sk IN (
         SELECT p.p_item_sk
         FROM promotion p
         WHERE p.p_cost > 5000
     )
),
web_ret AS (
   SELECT
      c.c_customer_id AS customer_id,
      wr.wr_return_amt AS return_amount,
      r.r_reason_desc AS reason_desc,
      'Web' AS channel
   FROM web_returns wr
   JOIN web_sales ws
     ON wr.wr_order_number = ws.ws_order_number
   JOIN customer c
     ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_net_loss > 1000
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = ws.ws_promo_sk
           AND p.p_discount_active = 'Y'
     )
)
SELECT DISTINCT
   customer_id,
   return_amount,
   reason_desc,
   channel
FROM (
   SELECT customer_id, return_amount, reason_desc, channel FROM catalog_ret
   UNION ALL
   SELECT customer_id, return_amount, reason_desc, channel FROM web_ret
) combined
ORDER BY return_amount DESC
LIMIT 100
