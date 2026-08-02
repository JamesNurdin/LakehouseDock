WITH base AS (
    SELECT
        s.s_state,
        i.i_category,
        d_date.d_year,
        COALESCE(SUM(ss.ss_net_paid), 0) + COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid,
        COALESCE(SUM(ss.ss_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amt,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_on_hand,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_online_orders
    FROM store_sales ss
    JOIN date_dim d_date
        ON ss.ss_sold_date_sk = d_date.d_date_sk
    JOIN time_dim t_time
        ON ss.ss_sold_time_sk = t_time.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_date.d_date_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_date.d_date_sk
    LEFT JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN web_page wp_ret
        ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_date.d_year = 2001
      AND t_time.t_hour >= 9
      AND i.i_brand = 'Brand#12'
      AND s.s_state IN ('TX', 'CA')
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_ext_discount_amt > 0
    GROUP BY ROLLUP (s.s_state, i.i_category, d_date.d_year)
)
SELECT
    s_state,
    i_category,
    d_year,
    total_net_paid,
    total_net_profit,
    total_return_amt,
    total_on_hand,
    distinct_customers,
    distinct_online_orders,
    RANK() OVER (PARTITION BY s_state ORDER BY total_net_paid DESC) AS sales_rank_state,
    SUM(total_net_paid) OVER (PARTITION BY s_state ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_year
FROM base
ORDER BY s_state, i_category, d_year
