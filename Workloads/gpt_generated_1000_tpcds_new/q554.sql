WITH cte_intersect AS (
    SELECT c.c_customer_sk
    FROM tpcds.customer c
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1960 AND 2000
      AND c.c_birth_month = 5
      AND c.c_birth_day IN (8, 14, 23)
      AND c.c_current_addr_sk IS NOT NULL
    INTERSECT
    SELECT c2.c_customer_sk
    FROM tpcds.customer_address ca
    JOIN tpcds.customer c2 ON c2.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county IN ('Richland County', 'Noxubee County')
      AND ca.ca_suite_number LIKE 'Suite %'
      AND ca.ca_state <> 'ZZ'
      AND ca.ca_gmt_offset BETWEEN -5 AND 5
      AND ca.ca_zip IS NOT NULL
),

cte_union AS (
    SELECT c.c_customer_sk FROM tpcds.customer c WHERE c.c_birth_day = 30
    UNION
    SELECT c.c_customer_sk FROM tpcds.customer c WHERE c.c_birth_day = 14
),

full_joined AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_county,
        ca.ca_city,
        ca.ca_state,
        ca.ca_suite_number,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        ARRAY[ca.ca_city, ca.ca_state] AS location_parts
    FROM tpcds.customer c
    LEFT JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    FULL OUTER JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_current_hdemo_sk IN (
        SELECT hd_inner.hd_demo_sk
        FROM tpcds.household_demographics hd_inner
        WHERE hd_inner.hd_vehicle_count > 1
    )
)
SELECT
    fj.c_customer_sk,
    fj.c_first_name,
    fj.c_last_name,
    fj.ca_county,
    fj.ca_city,
    fj.ca_state,
    fj.ca_suite_number,
    fj.hd_dep_count,
    fj.hd_vehicle_count,
    fj.hd_buy_potential,
    loc_part AS location_component,
    ROW_NUMBER() OVER (PARTITION BY fj.ca_county ORDER BY fj.hd_dep_count DESC) AS dept_rank
FROM full_joined fj
JOIN cte_intersect i ON fj.c_customer_sk = i.c_customer_sk
JOIN cte_union u ON fj.c_customer_sk = u.c_customer_sk
CROSS JOIN UNNEST(fj.location_parts) AS t(loc_part)
WHERE fj.ca_suite_number LIKE 'Suite %'
  AND fj.ca_county NOT IN ('Potter County')
  AND fj.hd_buy_potential = '1001-5000'
  AND fj.hd_vehicle_count >= 0
  AND fj.c_first_name IS NOT NULL
ORDER BY dept_rank, fj.c_customer_sk
