SELECT
    i.i_category,
    i.i_brand,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    (SELECT COUNT(*)
     FROM customer c
     JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
     JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
     WHERE hd.hd_income_band_sk = 5
       AND ca.ca_state = 'CA') AS high_income_ca_customers
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
WHERE p.p_start_date_sk BETWEEN 2448000 AND 2450000
GROUP BY i.i_category, i.i_brand
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 10
