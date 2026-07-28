WITH store_agg AS (
   SELECT
     'store' AS source_type,
     s.s_store_id AS identifier,
     ss.ss_sold_date_sk AS date_sk,
     SUM(ss.ss_net_profit) AS amount,
     CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS category
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE s.s_tax_percentage > 0.05
     AND ss.ss_quantity > 0
   GROUP BY s.s_store_id, ss.ss_sold_date_sk
),
catalog_agg AS (
   SELECT
     'catalog' AS source_type,
     p.p_promo_id AS identifier,
     cr.cr_returned_date_sk AS date_sk,
     SUM(cr.cr_net_loss) AS amount,
     CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS category
   FROM catalog_returns cr
   JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cr.cr_return_quantity > 0
     AND cr.cr_fee > 20
   GROUP BY p.p_promo_id, cr.cr_returned_date_sk
)
SELECT DISTINCT
   source_type,
   identifier,
   date_sk,
   amount,
   category
FROM (
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM catalog_agg
) combined
ORDER BY amount DESC
LIMIT 100
