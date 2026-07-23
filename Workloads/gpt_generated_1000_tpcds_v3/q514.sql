WITH high_discount_city_sales AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_gmt_offset = -6.00
      AND ca.ca_zip IN ('48930', '39431')
      AND ss.ss_ext_discount_amt > 100
      AND ss.ss_wholesale_cost < 50
      AND ss.ss_sales_price > 500
      AND ss.ss_customer_sk IN (
          SELECT DISTINCT ss2.ss_customer_sk
          FROM store_sales ss2
          WHERE ss2.ss_ext_discount_amt > 200
      )
      AND ss.ss_ext_discount_amt > 500
    GROUP BY ca.ca_city, ca.ca_state
),
low_discount_city_sales AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_gmt_offset = -6.00
      AND ca.ca_zip IN ('48930', '39431')
      AND ss.ss_ext_discount_amt > 100
      AND ss.ss_wholesale_cost < 50
      AND ss.ss_sales_price > 500
      AND ss.ss_customer_sk IN (
          SELECT DISTINCT ss2.ss_customer_sk
          FROM store_sales ss2
          WHERE ss2.ss_ext_discount_amt > 200
      )
      AND ss.ss_ext_discount_amt <= 500
    GROUP BY ca.ca_city, ca.ca_state
),
combined_city_sales AS (
    SELECT ca_city, ca_state, total_net_paid, total_net_profit, avg_discount, distinct_tickets
    FROM high_discount_city_sales
    UNION ALL
    SELECT ca_city, ca_state, total_net_paid, total_net_profit, avg_discount, distinct_tickets
    FROM low_discount_city_sales
)
SELECT
    ca_city,
    ca_state,
    SUM(total_net_paid) AS sum_net_paid,
    SUM(total_net_profit) AS sum_net_profit,
    AVG(avg_discount) AS avg_discount_overall,
    SUM(distinct_tickets) AS total_distinct_tickets,
    CASE
        WHEN SUM(total_net_profit) > 10000 THEN 'Very High'
        WHEN SUM(total_net_profit) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS profit_category
FROM combined_city_sales
GROUP BY ca_city, ca_state
ORDER BY sum_net_profit DESC
LIMIT 100
