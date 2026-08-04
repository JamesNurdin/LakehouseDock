WITH
    sampled_store AS (
        SELECT *
        FROM store TABLESAMPLE BERNOULLI (10)
    ),
    filtered_store AS (
        SELECT
            s_store_sk,
            s_city,
            s_state,
            s_suite_number,
            s_street_name,
            CONCAT(s_city, ', ', s_state) AS city_state
        FROM sampled_store
        WHERE regexp_like(s_suite_number, '^Suite [0-9]+')
          AND s_street_name LIKE '%Park%'
    ),
    joined AS (
        SELECT
            sr.sr_store_sk,
            sr.sr_return_amt_inc_tax,
            sr.sr_store_credit,
            sr.sr_return_quantity,
            f.s_city,
            f.s_state,
            f.city_state
        FROM filtered_store f
        JOIN store_returns sr
          ON sr.sr_store_sk = f.s_store_sk
        WHERE sr.sr_return_amt_inc_tax > 100
    ),
    agg1 AS (
        SELECT
            f.s_state AS state,
            f.s_city AS city,
            SUM(j.sr_return_amt_inc_tax) AS total_return_amt,
            COUNT(*) AS cnt
        FROM joined j
        JOIN filtered_store f ON f.s_store_sk = j.sr_store_sk
        GROUP BY GROUPING SETS ( (f.s_state, f.s_city), (f.s_state), () )
    ),
    agg2 AS (
        SELECT
            f.s_state AS state,
            SUM(j.sr_store_credit) AS total_credit,
            COUNT(*) AS cnt
        FROM joined j
        JOIN filtered_store f ON f.s_store_sk = j.sr_store_sk
        WHERE regexp_extract(f.s_suite_number, '(\\d+)$') IS NOT NULL
        GROUP BY f.s_state
    ),
    intersect_keys AS (
        SELECT sr_store_sk FROM store_returns WHERE sr_return_quantity > 0
        INTERSECT
        SELECT s_store_sk FROM store WHERE s_market_id IS NOT NULL
    ),
    final_agg1 AS (
        SELECT *
        FROM agg1
        WHERE state NOT IN (SELECT s_state FROM store WHERE s_country = 'CAN')
    ),
    final_agg2 AS (
        SELECT *
        FROM agg2
        WHERE state NOT IN (SELECT s_state FROM store WHERE s_country = 'CAN')
    )
SELECT
    state,
    city,
    total_return_amt,
    NULL AS total_credit,
    cnt
FROM final_agg1
UNION DISTINCT
SELECT
    state,
    NULL AS city,
    NULL AS total_return_amt,
    total_credit,
    cnt
FROM final_agg2
ORDER BY state, city
LIMIT 100
