WITH
    filtered_sales AS (
        SELECT
            ss.ss_addr_sk,
            ss.ss_ext_sales_price,
            ss.ss_sales_price,
            ss.ss_wholesale_cost,
            ss.ss_ext_discount_amt,
            ss.ss_ext_tax,
            ss.ss_quantity,
            ss.ss_net_profit
        FROM store_sales ss
        WHERE ss.ss_wholesale_cost > 30
          AND ss.ss_sales_price < 80
          AND ss.ss_ext_sales_price > 500
          AND ss.ss_quantity >= 1
    ),
    states_of_interest AS (
        SELECT ca_state FROM customer_address WHERE ca_city = 'Los Angeles'
        UNION
        SELECT ca_state FROM customer_address WHERE ca_city = 'Phoenix'
    ),
    joined AS (
        SELECT
            ca.ca_state,
            ca.ca_county,
            s.ss_ext_sales_price,
            s.ss_sales_price,
            s.ss_wholesale_cost,
            s.ss_ext_discount_amt,
            s.ss_ext_tax,
            s.ss_quantity,
            s.ss_net_profit
        FROM filtered_sales s
        JOIN customer_address ca
            ON s.ss_addr_sk = ca.ca_address_sk
        WHERE ca.ca_state IN (SELECT ca_state FROM states_of_interest)
          AND ca.ca_county = 'Maricopa County'
          AND ca.ca_street_type = 'Lane'
    )
SELECT
    ca_state,
    ca_county,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_sales_price) AS avg_sales_price,
    COUNT(*) AS transaction_cnt,
    MIN(ss_ext_discount_amt) AS min_discount,
    MAX(ss_ext_tax) AS max_tax,
    (SELECT AVG(ss_wholesale_cost) FROM store_sales) AS overall_avg_wholesale_cost,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(ss_ext_sales_price) DESC) AS state_sales_rank
FROM joined
GROUP BY ca_state, ca_county
ORDER BY total_sales DESC
LIMIT 100
