WITH promo_metrics AS (
   SELECT
       p.p_promo_sk,
       p.p_promo_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_ext_discount_amt) AS total_discount,
       SUM(p.p_cost) AS total_promo_cost,
       SUM(cs.cs_net_profit) AS total_net_profit
   FROM promotion p
   JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
   GROUP BY p.p_promo_sk, p.p_promo_name
),
promo_returns AS (
   SELECT
       p.p_promo_sk,
       SUM(sr.sr_net_loss) AS total_return_loss,
       SUM(sr.sr_return_amt) AS total_return_amount
   FROM promotion p
   JOIN item i ON p.p_item_sk = i.i_item_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   GROUP BY p.p_promo_sk
)
SELECT
   pm.p_promo_name,
   pm.total_sales,
   pm.total_discount,
   pm.total_promo_cost,
   COALESCE(pr.total_return_loss, 0) AS total_return_loss,
   (pm.total_sales - pm.total_discount - pm.total_promo_cost - COALESCE(pr.total_return_loss, 0)) AS net_gain,
   NTILE(4) OVER (ORDER BY (pm.total_sales - pm.total_discount - pm.total_promo_cost - COALESCE(pr.total_return_loss, 0)) DESC) AS gain_quartile,
   CASE
       WHEN (pm.total_sales - pm.total_discount - pm.total_promo_cost - COALESCE(pr.total_return_loss, 0)) > 10000 THEN 'HIGH'
       WHEN (pm.total_sales - pm.total_discount - pm.total_promo_cost - COALESCE(pr.total_return_loss, 0)) BETWEEN 5000 AND 10000 THEN 'MEDIUM'
       ELSE 'LOW'
   END AS performance_tier
FROM promo_metrics pm
LEFT JOIN promo_returns pr ON pm.p_promo_sk = pr.p_promo_sk
ORDER BY net_gain DESC
LIMIT 15
