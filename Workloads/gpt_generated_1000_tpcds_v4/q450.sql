WITH dim_2001 AS (
    SELECT d_date_sk,
           d_date,
           d_year
    FROM date_dim
    WHERE d_year = 2001
)
SELECT return_date,
       category,
       total_return_amount
FROM (
    -- Returns linked to active promotions in 2001
    SELECT d.d_date AS return_date,
           p.p_promo_name AS category,
           SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN dim_2001 d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN promotion p
      ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY d.d_date,
             p.p_promo_name
    UNION ALL
    -- Returns shipped via AIR mode in 2001
    SELECT d.d_date AS return_date,
           sm.sm_type AS category,
           SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN dim_2001 d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
    GROUP BY d.d_date,
             sm.sm_type
) combined
ORDER BY return_date DESC,
         total_return_amount DESC
LIMIT 100
