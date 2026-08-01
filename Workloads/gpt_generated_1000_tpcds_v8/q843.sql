WITH agg AS (
    SELECT
        c.c_customer_sk,
        c.c_last_name,
        c.c_email_address,
        t.t_shift,
        SUM(ws.ws_ext_sales_price)               AS total_ws_sales,
        SUM(sr.sr_return_amt)                    AS total_sr_return,
        COUNT(DISTINCT ws.ws_order_number)        AS ws_orders,
        COUNT(DISTINCT sr.sr_ticket_number)      AS sr_returns
    FROM
        customer c
        JOIN store_returns sr TABLESAMPLE BERNOULLI (10) ON sr.sr_customer_sk = c.c_customer_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                           AND ws.ws_sold_time_sk = t.t_time_sk
    WHERE
        c.c_last_review_date >= 2452400 AND
        c.c_birth_month = 5 AND
        c.c_preferred_cust_flag = 'Y' AND
        c.c_email_address LIKE '%@%' AND
        t.t_am_pm = 'PM' AND
        t.t_second BETWEEN 5 AND 15 AND
        ws.ws_ext_list_price > 1000
    GROUP BY GROUPING SETS (
        (c.c_customer_sk, c.c_last_name, c.c_email_address, t.t_shift),
        (c.c_customer_sk, t.t_shift)
    )
)
SELECT
    a.c_customer_sk,
    a.c_last_name,
    a.c_email_address,
    a.t_shift,
    a.total_ws_sales,
    a.total_sr_return,
    a.ws_orders,
    a.sr_returns,
    (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = a.c_customer_sk
    ) AS avg_sales_price_per_customer,
    SUM(a.total_ws_sales) OVER (
        PARTITION BY a.t_shift
        ORDER BY a.c_customer_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_sales_by_shift,
    LAG(a.total_ws_sales, 1, 0) OVER (
        PARTITION BY a.t_shift
        ORDER BY a.c_customer_sk
    ) AS prev_customer_sales
FROM
    agg a
WHERE
    a.total_ws_sales > 5000 AND
    a.total_sr_return < 2000
ORDER BY
    a.total_ws_sales DESC
LIMIT 100
