WITH promo_sales AS (
   SELECT
       p.p_promo_sk,
       p.p_promo_name,
       i.i_category,
       SUM(cs.cs_net_profit) AS total_net_profit,
       SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
       SUM(cs.cs_ext_sales_price) AS total_sales_amount
   FROM promotion p
   JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   GROUP BY p.p_promo_sk, p.p_promo_name, i.i_category
),
promo_returns AS (
   SELECT
       p.p_promo_sk,
       SUM(sr.sr_net_loss) AS total_net_loss,
       SUM(sr.sr_return_amt) AS total_return_amount
   FROM promotion p
   JOIN item i ON p.p_item_sk = i.i_item_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   GROUP BY p.p_promo_sk
)
SELECT
   ps.p_promo_name,
   ps.i_category,
   ps.total_net_profit,
   COALESCE(pr.total_net_loss, 0) AS total_net_loss,
   ps.total_discount_amount,
   CASE
       WHEN ps.total_net_profit - COALESCE(pr.total_net_loss, 0) > 0 THEN 'POSITIVE'
       ELSE 'NEGATIVE'
   END AS net_gain_status,
   DENSE_RANK() OVER (ORDER BY (ps.total_net_profit - COALESCE(pr.total_net_loss, 0)) DESC) AS profit_rank
FROM promo_sales ps
LEFT JOIN promo_returns pr ON ps.p_promo_sk = pr.p_promo_sk
ORDER BY profit_rank
LIMIT 10
