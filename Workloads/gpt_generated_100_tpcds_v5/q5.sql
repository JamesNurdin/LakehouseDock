WITH sales_by_city AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_zip = '68252'
      AND ss.ss_promo_sk = 1145
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT
    ca_city,
    ca_state,
    total_net_paid,
    total_net_profit,
    sales_cnt
FROM sales_by_city
ORDER BY total_net_paid DESC
LIMIT 100
