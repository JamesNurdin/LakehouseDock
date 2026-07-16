WITH aggregated AS (
    SELECT
        ca.ca_state AS state,
        p.p_promo_name AS promo_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        SUM(ss.ss_ext_discount_amt) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS discount_rate
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 12 AND 14
      AND ca.ca_country = 'United States'
      AND ss.ss_net_profit > 0
    GROUP BY ca.ca_state, p.p_promo_name
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    state,
    promo_name,
    num_transactions,
    total_net_profit,
    total_sales,
    total_quantity,
    avg_discount_amt,
    discount_rate,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_net_profit DESC) AS promo_rank_in_state
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
