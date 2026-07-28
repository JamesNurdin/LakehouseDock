WITH catalog_agg AS (
   SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      SUM(cr.cr_net_loss) AS catalog_net_loss,
      COUNT(*) AS catalog_return_cnt
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '\\d{2,}')
     AND i.i_item_desc LIKE '%Gold%'
   GROUP BY cr.cr_refunded_customer_sk
),
web_agg AS (
   SELECT
      wr.wr_refunded_customer_sk AS customer_sk,
      SUM(wr.wr_net_loss) AS web_net_loss,
      COUNT(*) AS web_return_cnt
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE regexp_like(p.p_promo_name, '^Promo.*')
     AND p.p_channel_email = 'Y'
     AND i.i_item_desc LIKE '%Gold%'
   GROUP BY wr.wr_refunded_customer_sk
)
SELECT
   c.c_customer_id,
   c.c_first_name || ' ' || c.c_last_name AS customer_name,
   COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
   COALESCE(ca.catalog_return_cnt, 0) AS catalog_returns,
   COALESCE(wa.web_return_cnt, 0) AS web_returns,
   (
      SELECT AVG(p2.p_cost)
      FROM web_sales ws2
      JOIN promotion p2 ON ws2.ws_promo_sk = p2.p_promo_sk
      WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
   ) AS avg_promo_cost
FROM customer c
LEFT JOIN catalog_agg ca ON c.c_customer_sk = ca.customer_sk
LEFT JOIN web_agg wa ON c.c_customer_sk = wa.customer_sk
WHERE (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
