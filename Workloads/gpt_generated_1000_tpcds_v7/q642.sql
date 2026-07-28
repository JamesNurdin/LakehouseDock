WITH sales_tn AS (
    SELECT s.s_division_id,
           s.s_division_name,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'TN'
      AND s.s_market_id = 10
      AND c.c_first_sales_date_sk >= 2449150
    GROUP BY s.s_division_id, s.s_division_name
    HAVING SUM(ss.ss_net_profit) > 10000
),
sales_co AS (
    SELECT s.s_division_id,
           s.s_division_name,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CO'
      AND s.s_market_id = 6
      AND c.c_salutation = 'Mr.'
    GROUP BY s.s_division_id, s.s_division_name
    HAVING SUM(ss.ss_net_profit) > 5000
)
SELECT s_division_id,
       s_division_name,
       total_net_profit
FROM sales_tn
UNION ALL
SELECT s_division_id,
       s_division_name,
       total_net_profit
FROM sales_co
ORDER BY total_net_profit DESC
LIMIT 100
