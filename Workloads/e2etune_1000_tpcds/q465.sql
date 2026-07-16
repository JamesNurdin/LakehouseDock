WITH sales_agg AS (
    SELECT
        c.c_current_cdemo_sk AS cust_demo_sk,
        t.t_hour,
        t.t_shift,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_returns_loss,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_returns_loss,
        (SUM(ws.ws_net_paid_inc_tax) - COALESCE(SUM(wr.wr_net_loss), 0) - COALESCE(SUM(sr.sr_net_loss), 0)) AS net_revenue
    FROM
        web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk
            AND wr.wr_returned_time_sk = t.t_time_sk
        LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
            AND sr.sr_return_time_sk = t.t_time_sk
    WHERE
        c.c_birth_year >= 1950
        AND t.t_shift = 'Evening'
        AND ws.ws_sold_date_sk BETWEEN 2450821 AND 2452168
    GROUP BY
        c.c_current_cdemo_sk,
        t.t_hour,
        t.t_shift
    HAVING
        COUNT(DISTINCT ws.ws_order_number) >= 10
)
SELECT
    cust_demo_sk,
    t_hour,
    t_shift,
    orders,
    total_web_sales,
    total_web_profit,
    total_web_returns_loss,
    total_store_returns_loss,
    net_revenue,
    RANK() OVER (ORDER BY total_web_sales DESC) AS sales_rank
FROM
    sales_agg
ORDER BY
    net_revenue DESC
LIMIT 100
