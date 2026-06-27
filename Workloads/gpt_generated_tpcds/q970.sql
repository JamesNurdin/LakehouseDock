WITH
    -- Aggregate store sales per customer
    store_sales_agg AS (
        SELECT
            c.c_customer_sk,
            SUM(ss.ss_net_paid)      AS store_sales_net_paid,
            SUM(ss.ss_net_profit)    AS store_sales_net_profit,
            COUNT(*)                 AS store_sales_txn_cnt
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk
    ),
    -- Aggregate store returns per customer
    store_returns_agg AS (
        SELECT
            c.c_customer_sk,
            SUM(sr.sr_net_loss)   AS store_returns_net_loss,
            SUM(sr.sr_return_amt) AS store_returns_amount,
            COUNT(*)               AS store_returns_txn_cnt
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk
    ),
    -- Aggregate web sales per customer (billing side)
    web_sales_agg AS (
        SELECT
            c.c_customer_sk,
            SUM(ws.ws_net_paid)    AS web_sales_net_paid,
            SUM(ws.ws_net_profit)  AS web_sales_net_profit,
            COUNT(*)               AS web_sales_txn_cnt
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk
    ),
    -- Aggregate web returns per customer (refunded side)
    web_returns_agg AS (
        SELECT
            c.c_customer_sk,
            SUM(wr.wr_net_loss)   AS web_returns_net_loss,
            SUM(wr.wr_return_amt) AS web_returns_amount,
            COUNT(*)               AS web_returns_txn_cnt
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk
    ),
    -- Map each customer to its current state and preferred‑customer flag
    customer_state AS (
        SELECT
            c.c_customer_sk,
            c.c_preferred_cust_flag,
            ca.ca_state
        FROM customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    )
SELECT
    cs.ca_state,
    SUM(
        COALESCE(ss.store_sales_net_profit, 0)
        - COALESCE(sr.store_returns_net_loss, 0)
        + COALESCE(ws.web_sales_net_profit, 0)
        - COALESCE(wr.web_returns_net_loss, 0)
    ) AS net_total_profit,
    COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
    SUM(
        COALESCE(ss.store_sales_net_paid, 0)
        + COALESCE(ws.web_sales_net_paid, 0)
    ) AS total_sales_paid
FROM customer_state cs
LEFT JOIN store_sales_agg   ss ON ss.c_customer_sk = cs.c_customer_sk
LEFT JOIN store_returns_agg sr ON sr.c_customer_sk = cs.c_customer_sk
LEFT JOIN web_sales_agg    ws ON ws.c_customer_sk = cs.c_customer_sk
LEFT JOIN web_returns_agg  wr ON wr.c_customer_sk = cs.c_customer_sk
WHERE cs.c_preferred_cust_flag = 'Y'
GROUP BY cs.ca_state
ORDER BY net_total_profit DESC
LIMIT 5
