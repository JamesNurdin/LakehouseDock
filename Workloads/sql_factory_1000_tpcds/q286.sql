WITH store_agg AS (
    SELECT ss_customer_sk AS cust_sk,
           SUM(ss_net_profit) AS store_profit,
           SUM(ss_net_paid) AS store_paid
    FROM store_sales
    GROUP BY ss_customer_sk
),
web_agg AS (
    SELECT ws_bill_customer_sk AS cust_sk,
           SUM(ws_net_profit) AS web_profit,
           SUM(ws_net_paid) AS web_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_agg AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           ca.ca_state,
           COALESCE(st.store_profit, 0) AS store_profit,
           COALESCE(wt.web_profit, 0) AS web_profit,
           COALESCE(st.store_paid, 0) AS store_paid,
           COALESCE(wt.web_paid, 0) AS web_paid
    FROM customer c
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_agg st
        ON st.cust_sk = c.c_customer_sk
    LEFT JOIN web_agg wt
        ON wt.cust_sk = c.c_customer_sk
)
SELECT
    cust.c_customer_id,
    cust.ca_state,
    cust.store_profit,
    cust.web_profit,
    cust.store_paid,
    cust.web_paid,
    (cust.store_profit + cust.web_profit) AS total_profit,
    (cust.store_paid + cust.web_paid) AS total_paid,
    CASE 
        WHEN (cust.store_paid + cust.web_paid) = 0 THEN NULL
        ELSE (cust.store_profit + cust.web_profit) / (cust.store_paid + cust.web_paid)
    END AS profit_margin,
    CASE 
        WHEN (cust.store_profit + cust.web_profit) / NULLIF((cust.store_paid + cust.web_paid), 0) > 0.20 THEN 'Excellent'
        WHEN (cust.store_profit + cust.web_profit) / NULLIF((cust.store_paid + cust.web_paid), 0) > 0.10 THEN 'Good'
        WHEN (cust.store_profit + cust.web_profit) / NULLIF((cust.store_paid + cust.web_paid), 0) > 0.05 THEN 'Average'
        ELSE 'Below Average'
    END AS margin_category,
    DENSE_RANK() OVER (ORDER BY 
        CASE 
            WHEN (cust.store_paid + cust.web_paid) = 0 THEN 0
            ELSE (cust.store_profit + cust.web_profit) / (cust.store_paid + cust.web_paid)
        END DESC
    ) AS margin_rank,
    SUM(cust.store_profit + cust.web_profit) OVER (PARTITION BY cust.ca_state) AS state_total_profit
FROM customer_agg cust
WHERE (cust.store_paid + cust.web_paid) > 0
ORDER BY margin_rank
LIMIT 15
