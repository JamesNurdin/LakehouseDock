WITH sampled_customers AS (
        SELECT *
        FROM customer
        TABLESAMPLE BERNOULLI (10)
    ),
    eligible_customers AS (
        SELECT c_customer_id
        FROM sampled_customers
        WHERE c_birth_month = 9
          AND c_birth_year = 1972
        EXCEPT
        SELECT c_customer_id
        FROM sampled_customers
        WHERE c_birth_year = 1973
    )
SELECT
    d_ship.d_year,
    i.i_category,
    cd AS channel_detail,
    COUNT(DISTINCT sc.c_customer_id) AS customer_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(p.p_cost) AS min_promo_cost,
    MAX(p.p_cost) AS max_promo_cost
FROM sampled_customers AS sc
JOIN date_dim AS d_ship
    ON sc.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim AS d_sales
    ON sc.c_first_sales_date_sk = d_sales.d_date_sk
JOIN promotion AS p
    ON p.p_start_date_sk = d_ship.d_date_sk
JOIN date_dim AS d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN item AS i
    ON p.p_item_sk = i.i_item_sk
CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t (cd)
WHERE p.p_channel_catalog = 'N'
  AND p.p_channel_email = 'N'
  AND d_ship.d_year = 1998
  AND d_ship.d_following_holiday = 'N'
  AND EXISTS (
        SELECT 1
        FROM eligible_customers ec
        WHERE ec.c_customer_id = sc.c_customer_id
    )
GROUP BY d_ship.d_year, i.i_category, cd
ORDER BY total_promo_cost DESC, customer_cnt DESC
OFFSET 0 LIMIT 100
