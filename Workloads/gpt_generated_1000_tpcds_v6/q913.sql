WITH filtered_addr AS (
    SELECT
        ca_address_sk,
        ca_state,
        ca_suite_number,
        ca_address_id,
        ca_city,
        CONCAT(ca_city, ', ', ca_state) AS city_state,
        regexp_extract(ca_address_id, '(A{7})([A-Z])', 2) AS addr_code
    FROM tpcds.customer_address
    WHERE regexp_like(ca_suite_number, '^Suite [A-Z]')
      AND ca_address_id LIKE 'AAAAAAA%'
      AND CONCAT(ca_city, ca_state) LIKE '%York%'
),
sales_filtered AS (
    SELECT
        ws_bill_addr_sk,
        ws_ext_list_price,
        ws_net_profit,
        ws_quantity
    FROM tpcds.web_sales
    WHERE ws_ext_list_price BETWEEN 2000 AND 15000
      AND ws_quantity > 1
)
SELECT
    fa.ca_state,
    COUNT(DISTINCT fa.ca_address_id) AS distinct_address_cnt,
    SUM(sf.ws_net_profit) AS total_net_profit,
    AVG(sf.ws_ext_list_price) AS avg_ext_list_price,
    MAX(fa.addr_code) AS sample_addr_code
FROM filtered_addr fa
JOIN sales_filtered sf
    ON sf.ws_bill_addr_sk = fa.ca_address_sk
GROUP BY fa.ca_state
HAVING SUM(sf.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 20
