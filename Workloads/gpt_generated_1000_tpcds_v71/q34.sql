WITH joined AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_order_number,
       cr.cr_item_sk,
       ca.ca_state,
       cd.cd_credit_rating,
       d_ret.d_year,
       p.p_promo_name,
       p.p_cost,
       p.p_channel_event
   FROM catalog_returns cr
   JOIN date_dim d_ret
       ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN customer_address ca
       ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
       ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN promotion p
       ON cr.cr_item_sk = p.p_item_sk
   LEFT JOIN date_dim d_start
       ON p.p_start_date_sk = d_start.d_date_sk
   LEFT JOIN date_dim d_end
       ON p.p_end_date_sk = d_end.d_date_sk
   WHERE d_ret.d_year = 2001
     AND ca.ca_state = 'CA'
     AND cd.cd_credit_rating = 'Low Risk'
     AND (p.p_promo_name = 'bar' OR p.p_promo_name IS NULL)
     AND cr.cr_return_quantity > 1
     AND NOT EXISTS (
         SELECT 1 FROM promotion p2
         WHERE p2.p_item_sk = cr.cr_item_sk
           AND p2.p_promo_name = 'anti'
           AND p2.p_channel_event = 'Y'
     )
), agg AS (
   SELECT
       d_year,
       ca_state,
       cd_credit_rating,
       p_promo_name,
       SUM(cr_return_amount) AS total_return_amount,
       AVG(cr_return_tax) AS avg_return_tax,
       COUNT(DISTINCT cr_order_number) AS distinct_orders,
       MIN(cr_return_amount) AS min_return_amount,
       MAX(cr_return_amount) AS max_return_amount,
       CASE WHEN SUM(cr_return_amount) > 5000 THEN 'High' ELSE 'Normal' END AS return_category
   FROM joined
   GROUP BY d_year, ca_state, cd_credit_rating, p_promo_name
   HAVING SUM(cr_return_amount) > 1000
)
SELECT
   d_year,
   ca_state,
   cd_credit_rating,
   p_promo_name,
   total_return_amount,
   avg_return_tax,
   distinct_orders,
   min_return_amount,
   max_return_amount,
   return_category,
   ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_within_year,
   (SELECT AVG(p_cost) FROM promotion WHERE p_channel_event = 'N') AS avg_promo_cost_no_event
FROM agg
ORDER BY d_year, total_return_amount DESC
LIMIT 100
