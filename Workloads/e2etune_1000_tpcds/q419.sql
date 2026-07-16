WITH cust_agg AS (
    SELECT
        c.c_birth_year,
        c.c_birth_month,
        ca.ca_country,
        ca.ca_state,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_day) AS avg_birth_day,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cust_cnt
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month = 4
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND ca.ca_state = 'CA'
    GROUP BY c.c_birth_year, c.c_birth_month, ca.ca_country, ca.ca_state
    HAVING COUNT(*) > 5
)
SELECT
    agg.c_birth_year,
    agg.c_birth_month,
    agg.ca_country,
    agg.ca_state,
    agg.cust_cnt,
    agg.avg_birth_day,
    agg.pref_cust_cnt,
    (SELECT AVG(i_current_price) FROM item i WHERE i.i_category = 'Electronics') AS avg_elec_price,
    (SELECT COUNT(*) FROM ship_mode sm WHERE sm.sm_carrier = 'FedEx') AS fedex_mode_cnt,
    (SELECT COUNT(DISTINCT ca2.ca_state)
        FROM customer_address ca2
        WHERE ca2.ca_country = agg.ca_country
          AND ca2.ca_state <> agg.ca_state) AS other_state_cnt_in_country,
    (SELECT AVG(web_tax_percentage) FROM web_site ws WHERE ws.web_country = agg.ca_country) AS avg_tax_pct_in_country,
    ROW_NUMBER() OVER (ORDER BY agg.cust_cnt DESC) AS cust_rank
FROM cust_agg agg
ORDER BY agg.cust_cnt DESC
LIMIT 50
