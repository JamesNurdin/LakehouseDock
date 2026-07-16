WITH promo_item_agg AS (
    SELECT i.i_category,
           SUM(p.p_cost) AS total_promo_cost,
           AVG(i.i_current_price) AS avg_item_price,
           MAX(p.p_response_target) AS max_response_target
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_start_date_sk >= 2450000
      AND i.i_category = 'Sports'
    GROUP BY i.i_category
),
customer_demo_agg AS (
    SELECT cd.cd_gender,
           COUNT(DISTINCT c.c_customer_sk) AS num_customers,
           COUNT(*) AS total_customers
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
    GROUP BY cd.cd_gender
)
SELECT pi.i_category,
       cd.cd_gender,
       cd.num_customers,
       pi.total_promo_cost,
       pi.avg_item_price,
       pi.max_response_target,
       RANK() OVER (ORDER BY pi.total_promo_cost DESC) AS category_rank
FROM promo_item_agg pi
CROSS JOIN customer_demo_agg cd
WHERE pi.total_promo_cost > 10000
ORDER BY pi.total_promo_cost DESC
LIMIT 20
