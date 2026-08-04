WITH wp_agg AS (
    SELECT
        wp_customer_sk,
        COUNT(*) AS page_cnt,
        SUM(wp_link_count) AS total_links,
        MAX(wp_char_count) AS max_char_cnt,
        COUNT(DISTINCT wp_type) AS distinct_type_cnt
    FROM web_page
    WHERE wp_link_count >= 2                         -- predicate 1
      AND wp_type IN ('HOME', 'PRODUCT')              -- predicate 2
      AND wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'  -- predicate 3
    GROUP BY wp_customer_sk
),
filtered_cust AS (
    SELECT *
    FROM customer
    WHERE c_birth_year BETWEEN 1970 AND 1990               -- predicate 4
      AND c_preferred_cust_flag = 'Y'                       -- predicate 5
      AND c_last_review_date >= 2452000                    -- predicate 6
      AND c_first_shipto_date_sk IN (2449756, 2452106)      -- predicate 7
)
SELECT *
FROM (
    SELECT
        f.c_customer_id,
        f.c_first_name,
        f.c_last_name,
        f.c_birth_year,
        a.page_cnt,
        a.total_links,
        a.max_char_cnt,
        RANK() OVER (PARTITION BY f.c_birth_year ORDER BY a.total_links DESC) AS rnk
    FROM filtered_cust f
    INNER JOIN wp_agg a
        ON a.wp_customer_sk = f.c_customer_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = f.c_customer_sk
          AND wp.wp_type = 'HOME'
          AND wp.wp_link_count > 10                     -- predicates inside EXISTS
    )
      AND a.distinct_type_cnt >= 2                        -- predicate 8
) t
WHERE t.rnk <= 3                                            -- top‑k per birth year
ORDER BY t.c_birth_year, t.rnk
LIMIT 100
