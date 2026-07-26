WITH store_agg AS (
    SELECT ss_customer_sk AS cust_sk,
           SUM(ss_net_profit) AS store_net_profit,
           COUNT(*) AS store_sales_cnt
    FROM store_sales
    GROUP BY ss_customer_sk
),
web_agg AS (
    SELECT ws_bill_customer_sk AS cust_sk,
           SUM(ws_net_profit) AS web_net_profit,
           COUNT(*) AS web_sales_cnt
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
combined AS (
    SELECT COALESCE(s.cust_sk, w.cust_sk) AS cust_sk,
           COALESCE(s.store_net_profit, 0) AS store_net_profit,
           COALESCE(w.web_net_profit, 0) AS web_net_profit,
           COALESCE(s.store_sales_cnt, 0) AS store_sales_cnt,
           COALESCE(w.web_sales_cnt, 0) AS web_sales_cnt,
           COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit
    FROM store_agg s
    FULL OUTER JOIN web_agg w ON s.cust_sk = w.cust_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_education_status,
    total_net_profit,
    store_net_profit,
    web_net_profit,
    CASE
        WHEN total_net_profit >= 10000 THEN 'Platinum'
        WHEN total_net_profit >= 5000 THEN 'Gold'
        WHEN total_net_profit >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM combined cm
JOIN customer c ON cm.cust_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE total_net_profit IS NOT NULL
ORDER BY profit_rank
LIMIT 10
