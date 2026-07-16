WITH promo_brand_agg AS (
    SELECT i.i_brand,
           SUM(p.p_cost) AS total_promo_cost,
           COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
           AVG(i.i_current_price) AS avg_item_price
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_start_date_sk >= 2450800
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_brand
),
promo_brand AS (
    SELECT *,
           RANK() OVER (ORDER BY total_promo_cost DESC) AS brand_rank
    FROM promo_brand_agg
),
cust_state AS (
    SELECT ca.ca_state,
           COUNT(DISTINCT c.c_customer_sk) AS cust_cnt,
           AVG(c.c_birth_year) AS avg_birth_year
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL
    GROUP BY ca.ca_state
)
SELECT pb.i_brand,
       pb.total_promo_cost,
       pb.promo_cnt,
       pb.avg_item_price,
       pb.brand_rank,
       cs.ca_state,
       cs.cust_cnt,
       cs.avg_birth_year
FROM promo_brand pb
CROSS JOIN cust_state cs
ORDER BY pb.total_promo_cost DESC, cs.cust_cnt DESC
LIMIT 100
