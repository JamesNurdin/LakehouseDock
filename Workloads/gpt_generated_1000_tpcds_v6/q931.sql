WITH sales_agg AS (
   SELECT s.s_store_id AS s_store_id,
          i.i_brand AS i_brand,
          SUM(ss.ss_net_paid) AS net_amount
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_category = 'maternity'
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_item_sk = i.i_item_sk
           AND p.p_discount_active = 'Y'
     )
   GROUP BY s.s_store_id, i.i_brand
),
returns_agg AS (
   SELECT s.s_store_id AS s_store_id,
          i.i_brand AS i_brand,
          -SUM(sr.sr_refunded_cash) AS net_amount
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE i.i_class = 'accessories'
   GROUP BY s.s_store_id, i.i_brand
),
combined AS (
   SELECT s_store_id, i_brand, net_amount FROM sales_agg
   UNION ALL
   SELECT s_store_id, i_brand, net_amount FROM returns_agg
)
SELECT c.s_store_id,
       c.i_brand,
       c.net_amount,
       (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS avg_sales_per_transaction
FROM combined c
ORDER BY c.net_amount DESC
LIMIT 100
