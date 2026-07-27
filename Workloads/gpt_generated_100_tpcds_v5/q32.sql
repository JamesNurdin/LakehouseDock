WITH sales_with_address AS (
    SELECT
        ca.ca_state,
        ca.ca_location_type,
        ss.ss_net_profit,
        ss.ss_coupon_amt,
        CAST(regexp_extract(ca.ca_suite_number, '\\d+') AS integer) AS suite_number_digits,
        CASE WHEN ss.ss_coupon_amt > 1000 THEN 'High' ELSE 'Low' END AS coupon_category,
        concat(ca.ca_city, ', ', ca.ca_state) AS city_state
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_suite_number, '^Suite [0-9]+')
      AND ca.ca_city LIKE 'A%'
)
SELECT
    ca_state,
    ca_location_type,
    coupon_category,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_coupon_amt) AS avg_coupon_amt,
    MIN(suite_number_digits) AS min_suite_num,
    MAX(suite_number_digits) AS max_suite_num
FROM sales_with_address
GROUP BY ca_state, ca_location_type, coupon_category
ORDER BY total_profit DESC
LIMIT 100
