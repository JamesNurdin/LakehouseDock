WITH sales_by_cust_hour AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        t.t_hour,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid_inc_tax > 0
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, t.t_hour
),
returns_by_cust_hour AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        t.t_hour,
        SUM(sr.sr_net_loss) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS returns_cnt
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_net_loss > 0
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, t.t_hour
)
SELECT
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    s.t_hour,
    s.total_sales,
    r.total_returns,
    (s.total_sales - COALESCE(r.total_returns, 0)) AS net_balance,
    CASE WHEN COALESCE(r.total_returns, 0) = 0 THEN NULL
         ELSE s.total_sales / r.total_returns END AS sales_to_return_ratio,
    s.orders_cnt,
    r.returns_cnt
FROM sales_by_cust_hour s
LEFT JOIN returns_by_cust_hour r
    ON s.c_customer_id = r.c_customer_id
   AND s.t_hour = r.t_hour
WHERE s.total_sales > 1000
ORDER BY net_balance DESC
LIMIT 100
