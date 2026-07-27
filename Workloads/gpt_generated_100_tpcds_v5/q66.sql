WITH agg AS (
    SELECT
        s.s_state,
        t.t_hour,
        wp.wp_type,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(ws.ws_net_profit) AS total_web_profit,
        AVG(ws.ws_net_paid) AS avg_web_net_paid,
        MIN(ss.ss_sales_price) AS min_store_sales_price,
        MAX(ws.ws_sales_price) AS max_web_sales_price
    FROM customer c
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE c.c_email_address LIKE '%@EZmByJk.com'
      AND c.c_current_hdemo_sk IN (5559, 7190)
      AND s.s_state = 'CA'
      AND s.s_tax_percentage > 5.00
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.ws_net_profit > 0
      AND wp.wp_type = 'order'
      AND w.w_state = 'TX'
    GROUP BY s.s_state, t.t_hour, wp.wp_type
)
SELECT
    a.s_state,
    a.t_hour,
    a.wp_type,
    a.unique_customers,
    a.total_store_sales,
    a.total_return_amount,
    a.total_web_profit,
    a.avg_web_net_paid,
    a.min_store_sales_price,
    a.max_web_sales_price,
    SUM(a.total_store_sales) OVER (PARTITION BY a.s_state ORDER BY a.t_hour) AS running_store_sales
FROM agg a
ORDER BY a.s_state, a.t_hour DESC
LIMIT 100
