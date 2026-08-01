WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        c.c_current_addr_sk,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_location_type,
        ca.ca_gmt_offset,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        regexp_extract(c.c_email_address, '^(.*)@', 1) AS email_local_part,
        CASE
            WHEN regexp_like(c.c_email_address, '@example\\.com$') THEN 'example.com'
            ELSE 'other'
        END AS email_domain_category
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_location_type LIKE '%family%'
        AND ca.ca_zip LIKE '9%'
        AND c.c_birth_year BETWEEN 1970 AND 2000
)
SELECT
    b.c_customer_id,
    b.full_name,
    b.email_local_part,
    b.email_domain_category,
    substr(b.c_email_address, strpos(b.c_email_address, '@') + 1) AS email_domain,
    b.ca_state,
    b.ca_zip,
    b.c_birth_year,
    ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.c_birth_year DESC) AS state_birth_year_rank,
    (
        SELECT COUNT(*)
        FROM tpcds.customer_address ca2
        WHERE ca2.ca_state = b.ca_state
          AND ca2.ca_location_type = b.ca_location_type
    ) AS total_loc_type_in_state
FROM base b
WHERE NOT EXISTS (
        SELECT 1
        FROM tpcds.customer c2
        WHERE c2.c_customer_sk = b.c_customer_sk
          AND c2.c_preferred_cust_flag = 'Y'
    )
  AND EXISTS (
        SELECT 1
        FROM tpcds.customer_address ca3
        WHERE ca3.ca_state = b.ca_state
          AND ca3.ca_gmt_offset = b.ca_gmt_offset
          AND ca3.ca_address_sk <> b.c_current_addr_sk
    )
ORDER BY b.ca_state, state_birth_year_rank
LIMIT 100
