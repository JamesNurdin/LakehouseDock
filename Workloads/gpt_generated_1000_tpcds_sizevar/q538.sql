WITH agg_returns AS (
    SELECT cr_item_sk,
           COUNT(*) AS return_cnt,
           SUM(cr_return_amount) AS total_return_amount,
           AVG(cr_return_tax) AS avg_return_tax
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450200
      AND cr_return_quantity > 0
      AND cr_returned_time_sk < 1200
    GROUP BY cr_item_sk
),
promo_channels AS (
    SELECT p.p_promo_sk,
           p.p_item_sk,
           p.p_promo_name,
           ARRAY[p.p_channel_dmail, p.p_channel_email, p.p_channel_tv] AS channels
    FROM promotion p
    WHERE p.p_cost > 500
      AND p.p_discount_active = 'Y'
      AND p.p_start_date_sk >= 2450000
)
SELECT i.i_item_id,
       i.i_product_name,
       pc.p_promo_name,
       ch.channel,
       SUM(ar.return_cnt) AS total_returns,
       SUM(ar.total_return_amount) AS sum_return_amount,
       CASE WHEN SUM(ar.total_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level
FROM agg_returns ar
FULL OUTER JOIN promo_channels pc ON ar.cr_item_sk = pc.p_item_sk
LEFT JOIN UNNEST(pc.channels) AS ch (channel) ON TRUE
INNER JOIN item i ON i.i_item_sk = COALESCE(ar.cr_item_sk, pc.p_item_sk)
WHERE i.i_category = 'Electronics'
  AND i.i_rec_end_date > DATE '2000-01-01'
  AND i.i_container <> 'Unknown'
GROUP BY i.i_item_id,
         i.i_product_name,
         pc.p_promo_name,
         ch.channel
ORDER BY sum_return_amount DESC
OFFSET 0
LIMIT 100
