WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_coupon_amt,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_tax,
        ca.ca_city,
        ca.ca_state,
        ca.ca_street_type,
        ca.ca_zip
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_sales_price BETWEEN 10 AND 5000
      AND ss.ss_coupon_amt < 500
      AND ss.ss_ext_tax > 0
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND ca.ca_city NOT IN ('Fairfield')
      AND ca.ca_zip LIKE '9%'
)
SELECT
    ca_city,
    ca_state,
    ca_street_type,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(ss_net_paid) > 100000 THEN 'High'
        WHEN SUM(ss_net_paid) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category,
    RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ss_net_paid) DESC) AS state_city_rank,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        JOIN customer_address ca2
            ON ss2.ss_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_city = ca_city
          AND ss2.ss_coupon_amt > 1000
    ) AS high_coupon_sales_cnt
FROM filtered_sales
GROUP BY ca_city, ca_state, ca_street_type
ORDER BY total_net_paid DESC
LIMIT 100
