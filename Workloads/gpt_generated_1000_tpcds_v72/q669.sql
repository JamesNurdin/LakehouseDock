WITH full_join AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        d_sold.d_year,
        t_sold.t_shift,
        c.c_customer_sk,
        c.c_birth_day,
        ss.ss_ext_sales_price AS store_sales_amount,
        COALESCE(sr.sr_return_amt, 0) AS store_return_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        ws.ws_net_profit AS web_net_profit
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_store_sk = s.s_store_sk
           AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return
        ON sr.sr_return_time_sk = t_return.t_time_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
           AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_sold.d_year = 2002
      AND s.s_state = 'CA'
      AND t_sold.t_shift = 'first'
      AND c.c_birth_day = 17
      AND EXISTS (
          SELECT 1
          FROM customer c2
          WHERE c2.c_customer_sk = c.c_customer_sk
            AND c2.c_preferred_cust_flag = 'Y'
      )
),
agg AS (
    SELECT
        s_state,
        d_year,
        t_shift,
        SUM(store_sales_amount) AS total_store_sales,
        SUM(store_return_amount) AS total_store_returns,
        SUM(web_sales_amount) AS total_web_sales,
        SUM(web_net_profit) AS total_web_profit
    FROM full_join
    GROUP BY GROUPING SETS (
        (s_state, d_year, t_shift),
        (s_state, d_year),
        (s_state),
        ()
    )
)
SELECT u.s_state,
       u.metric_type,
       u.metric_value
FROM (
    SELECT s_state, 'store_sales' AS metric_type, total_store_sales AS metric_value
    FROM agg
    UNION ALL
    SELECT s_state, 'web_sales'   AS metric_type, total_web_sales   AS metric_value
    FROM agg
) u
WHERE u.metric_value > (
    SELECT AVG(v.metric_value)
    FROM (
        SELECT total_store_sales AS metric_value FROM agg
        UNION ALL
        SELECT total_web_sales   AS metric_value FROM agg
    ) v
)
ORDER BY u.s_state, u.metric_type DESC
