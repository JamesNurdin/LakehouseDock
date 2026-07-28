WITH sr_data AS (
   SELECT i.i_item_sk,
          i.i_category_id AS category_id,
          sr.sr_net_loss
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE i.i_size = 'medium'
     AND s.s_state = 'CA'
     AND sr.sr_return_tax > 50
),
cr_data AS (
   SELECT i.i_item_sk,
          i.i_category_id AS category_id,
          cr.cr_net_loss
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE i.i_category_id = 4
     AND cr.cr_return_tax > 20
)
SELECT category_id,
       SUM(net_loss) AS total_net_loss,
       COUNT(*) AS return_count
FROM (
   SELECT category_id, sr_net_loss AS net_loss FROM sr_data
   UNION ALL
   SELECT category_id, cr_net_loss AS net_loss FROM cr_data
) u
GROUP BY category_id
HAVING SUM(net_loss) > 1000
ORDER BY total_net_loss DESC
