WITH store_agg AS (
   SELECT i.i_item_id AS item_id,
          p.p_promo_name AS promo_name,
          SUM(ss.ss_net_paid) AS total_net_paid,
          COUNT(*) AS txn_count,
          'store' AS sales_channel
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE i.i_rec_start_date >= DATE '2000-01-01'
     AND p.p_discount_active = 'Y'
   GROUP BY i.i_item_id, p.p_promo_name
   HAVING SUM(ss.ss_net_paid) > 10000
),
web_agg AS (
   SELECT i.i_item_id AS item_id,
          p.p_promo_name AS promo_name,
          SUM(ws.ws_net_paid) AS total_net_paid,
          COUNT(*) AS txn_count,
          'web' AS sales_channel
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE i.i_rec_start_date >= DATE '2000-01-01'
     AND p.p_discount_active = 'Y'
   GROUP BY i.i_item_id, p.p_promo_name
   HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT item_id,
       promo_name,
       total_net_paid,
       txn_count,
       sales_channel
FROM store_agg
UNION ALL
SELECT item_id,
       promo_name,
       total_net_paid,
       txn_count,
       sales_channel
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
