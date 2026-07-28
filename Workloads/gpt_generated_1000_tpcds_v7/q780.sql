/*
Goal: Identify the most profitable customers (by net profit) across both store and web channels for male customers (salutation = 'Mr.') who bought at least three items per transaction. The query combines store‑sales profit and web‑sales profit using UNION ALL, preserving the channel source for each record.
*/
WITH store_profit AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS profit_amount,
        CAST('store' AS varchar) AS channel
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_salutation = 'Mr.'
      AND ss.ss_quantity >= 3
      AND ss.ss_net_profit > 0
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
),
web_profit AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS profit_amount,
        CAST('web' AS varchar) AS channel
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_salutation = 'Mr.'
      AND ws.ws_quantity >= 3
      AND ws.ws_net_profit > 0
      AND ws.ws_sales_price > 10.00
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    profit_amount,
    channel
FROM store_profit
UNION ALL
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    profit_amount,
    channel
FROM web_profit
ORDER BY profit_amount DESC
LIMIT 100
