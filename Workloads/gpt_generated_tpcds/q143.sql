WITH store_sales_by_customer AS (
    SELECT
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS store_sales_amount,
        SUM(ss_net_profit) AS store_profit,
        COUNT(*) AS store_txn_cnt
    FROM store_sales
    GROUP BY ss_customer_sk
),
web_sales_by_customer AS (
    SELECT
        ws_bill_customer_sk AS ws_customer_sk,
        SUM(ws_ext_sales_price) AS web_sales_amount,
        SUM(ws_net_profit) AS web_profit,
        COUNT(*) AS web_txn_cnt
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    COALESCE(ss.store_sales_amount, 0) AS store_sales_amount,
    COALESCE(ws.web_sales_amount, 0) AS web_sales_amount,
    COALESCE(ss.store_profit, 0) AS store_profit,
    COALESCE(ws.web_profit, 0) AS web_profit,
    COALESCE(ss.store_txn_cnt, 0) AS store_txn_cnt,
    COALESCE(ws.web_txn_cnt, 0) AS web_txn_cnt,
    (COALESCE(ss.store_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0)) AS total_sales_amount,
    (COALESCE(ss.store_profit, 0) + COALESCE(ws.web_profit, 0)) AS total_profit,
    (COALESCE(ss.store_txn_cnt, 0) + COALESCE(ws.web_txn_cnt, 0)) AS total_txn_cnt
FROM customer AS c
LEFT JOIN store_sales_by_customer AS ss
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN web_sales_by_customer AS ws
    ON ws.ws_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
ORDER BY total_sales_amount DESC
LIMIT 100
