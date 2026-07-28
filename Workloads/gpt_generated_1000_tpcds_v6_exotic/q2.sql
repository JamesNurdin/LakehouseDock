WITH per_county AS (
    SELECT
        ca.ca_county,
        COUNT(*) AS customer_cnt,
        AVG(customer.c_birth_day) AS avg_birth_day,
        SUM(customer.c_birth_day) AS sum_birth_day
    FROM
        tpcds.customer AS customer
    JOIN
        tpcds.customer_address AS ca
        ON customer.c_current_addr_sk = ca.ca_address_sk
    WHERE
        customer.c_birth_month = 5
        AND customer.c_birth_year >= 1970
        AND customer.c_preferred_cust_flag = 'Y'
        AND customer.c_last_name NOT IN ('Small', 'Norman')
        AND ca.ca_county LIKE '%County'
        AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
        AND EXISTS (
            SELECT 1
            FROM tpcds.customer_address ca2
            WHERE ca2.ca_state = ca.ca_state
              AND ca2.ca_zip = ca.ca_zip
              AND ca2.ca_address_sk <> ca.ca_address_sk
        )
    GROUP BY ca.ca_county
)
SELECT
    per_county.ca_county,
    per_county.customer_cnt,
    per_county.avg_birth_day
FROM per_county
WHERE per_county.customer_cnt > (
    SELECT AVG(customer_cnt) FROM per_county
)
ORDER BY per_county.customer_cnt DESC, per_county.ca_county
