WITH cust_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count
    FROM customer c
    INNER JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1970                     -- predicate 1
      AND cd.cd_credit_rating IN ('Low Risk', 'Good')             -- predicate 2
      AND cd.cd_dep_employed_count >= 1                            -- predicate 3
      AND cd.cd_purchase_estimate >= 2000                          -- predicate 4
),
web_agg AS (
    SELECT
        wp.wp_customer_sk,
        SUM(wp.wp_char_count) AS wp_char_sum,
        MAX(wp.wp_rec_start_date) AS max_start_date,
        MIN(wp.wp_rec_end_date)   AS min_end_date
    FROM web_page wp
    WHERE wp.wp_rec_start_date >= DATE '1999-01-01'               -- predicate 5
      AND wp.wp_rec_end_date   <= DATE '2001-12-31'               -- predicate 6
      AND wp.wp_url LIKE 'http://www.%'                           -- predicate 7
      AND wp.wp_type = 'content'                                  -- predicate 8
    GROUP BY wp.wp_customer_sk
)
SELECT
    cd.c_customer_id,
    cd.c_birth_year,
    cd.cd_credit_rating,
    cd.cd_purchase_estimate,
    COALESCE(wa.wp_char_sum, 0) AS total_char_count,
    CASE
        WHEN cd.cd_credit_rating = 'Low Risk' THEN 'A'
        ELSE 'B'
    END AS risk_category,
    ROW_NUMBER() OVER (
        PARTITION BY cd.cd_credit_rating
        ORDER BY COALESCE(wa.wp_char_sum, 0) DESC
    ) AS rank_in_rating,
    (
        SELECT AVG(cd2.cd_purchase_estimate)
        FROM customer_demographics cd2
        WHERE cd2.cd_credit_rating = cd.cd_credit_rating
    ) AS avg_purchase_estimate_for_rating
FROM cust_demo cd
LEFT OUTER JOIN web_agg wa
    ON wa.wp_customer_sk = cd.c_customer_sk                     -- outer join preserving customers without pages
WHERE cd.c_preferred_cust_flag = 'Y'                               -- predicate 9
ORDER BY cd.cd_credit_rating, rank_in_rating
LIMIT 100
