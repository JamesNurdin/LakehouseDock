/*
Goal: Identify the most tax‑heavy call centers (by tax percentage) that were open on the same date as a web site and a customer's first ship‑to date, limiting to recent years and specific geographic filters. The query pre‑aggregates call‑center counts and averages using GROUPING SETS, intersects two customer key sets, compares tax percentage to the overall maximum via a scalar sub‑query, ranks call centers within each state, and returns the top 100 rows.
*/
WITH
    cc_agg AS (
        SELECT
            cc_state,
            cc_country,
            COUNT(*) AS cnt_center,
            AVG(cc_tax_percentage) AS avg_tax,
            SUM(cc_employees) AS total_employees
        FROM call_center
        WHERE cc_gmt_offset BETWEEN -8.00 AND -5.00
              AND cc_zip LIKE '7%'
        GROUP BY GROUPING SETS ((cc_state), (cc_country))
    ),
    common_customers AS (
        SELECT c_customer_sk
        FROM (
            SELECT c_customer_sk
            FROM customer
            WHERE c_birth_year > 1950
        ) AS a
        INTERSECT
        SELECT c_customer_sk
        FROM customer
        WHERE c_preferred_cust_flag = 'Y'
    )
SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    cc.cc_country,
    cc.cc_tax_percentage,
    CASE
        WHEN cc.cc_tax_percentage = (SELECT MAX(cc_tax_percentage) FROM call_center) THEN 'MAX_TAX'
        ELSE 'NORMAL'
    END AS tax_category,
    ca.c_first_name,
    ca.c_last_name,
    ca.c_birth_year,
    ws.web_site_id,
    ws.web_state,
    d.d_year,
    d.d_moy,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY cc.cc_tax_percentage DESC) AS rn_state_tax,
    cnt_center,
    avg_tax,
    total_employees
FROM call_center cc
JOIN date_dim d
    ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN customer ca
    ON ca.c_first_shipto_date_sk = d.d_date_sk
JOIN cc_agg
    ON (cc.cc_state = cc_agg.cc_state OR cc.cc_country = cc_agg.cc_country)
JOIN common_customers com
    ON ca.c_customer_sk = com.c_customer_sk
WHERE
    cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
    AND cc.cc_zip LIKE '7%'
    AND d.d_moy IN (1, 2, 3)
    AND ca.c_birth_year BETWEEN 1950 AND 1965
    AND ws.web_state = 'CA'
ORDER BY rn_state_tax ASC, cc.cc_tax_percentage DESC
LIMIT 100
