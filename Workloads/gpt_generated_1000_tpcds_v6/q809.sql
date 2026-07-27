WITH division_sales_a AS (
    SELECT
        s.s_division_name,
        CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_market_desc LIKE '%Local%'
      AND ca.ca_state = 'CA'
    GROUP BY s.s_division_name
    HAVING SUM(ss.ss_net_profit) > 50000
),

division_sales_b AS (
    SELECT
        s.s_division_name,
        CASE WHEN SUM(ss.ss_net_profit) > 200000 THEN 'High' ELSE 'Low' END AS profit_category,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_market_desc LIKE '%Formal%'
      AND ca.ca_state = 'TX'
    GROUP BY s.s_division_name
    HAVING SUM(ss.ss_net_profit) > 80000
)
SELECT *
FROM division_sales_a
UNION ALL
SELECT *
FROM division_sales_b
ORDER BY total_profit DESC
