WITH profit_customers AS (
    SELECT
        c.c_customer_id,
        ca.ca_state AS state,
        SUM(ss.ss_net_profit) AS amount,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High Profit' ELSE 'Medium Profit' END AS category,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ss.ss_net_profit) DESC) AS state_rank,
        (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY c.c_customer_id, ca.ca_state
    HAVING SUM(ss.ss_net_profit) > 5000
),
return_customers AS (
    SELECT
        c.c_customer_id,
        ca.ca_state AS state,
        SUM(sr.sr_return_amt) AS amount,
        CASE WHEN SUM(sr.sr_return_amt) > 2000 THEN 'High Returns' ELSE 'Low Returns' END AS category,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(sr.sr_return_amt) DESC) AS state_rank,
        (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE EXISTS (
        SELECT 1 FROM reason r WHERE r.r_reason_sk = sr.sr_reason_sk AND r.r_reason_desc = 'Damaged'
    )
    GROUP BY c.c_customer_id, ca.ca_state
)
SELECT *
FROM (
    SELECT c_customer_id, state, amount, category, state_rank, max_income_upper FROM profit_customers
    UNION ALL
    SELECT c_customer_id, state, amount, category, state_rank, max_income_upper FROM return_customers
) combined
ORDER BY state, state_rank
