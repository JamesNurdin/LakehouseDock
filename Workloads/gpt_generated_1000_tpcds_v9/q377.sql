WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
),
joined_data AS (
    SELECT
        d_sales.d_year,
        s.s_state,
        s.s_store_name,
        SUM(sa.total_net_paid) AS sum_net_paid,
        SUM(sa.total_net_profit) AS sum_net_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS sum_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
        COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons,
        CASE
            WHEN SUM(sa.total_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(sa.total_net_profit) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM sales_agg sa
    JOIN store s
        ON sa.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON sa.ss_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN time_dim t_ret
        ON sr.sr_return_time_sk = t_ret.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
            OR ws.web_close_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN date_dim d_ws_open
        ON ws.web_open_date_sk = d_ws_open.d_date_sk
    LEFT JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_sales.d_year = 2001
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%return%'
    GROUP BY ROLLUP (d_sales.d_year, s.s_state, s.s_store_name)
)
SELECT
    d_year,
    s_state,
    s_store_name,
    sum_net_paid,
    sum_net_profit,
    sum_return_amt,
    distinct_return_tickets,
    distinct_return_reasons,
    profit_category,
    RANK() OVER (PARTITION BY d_year ORDER BY sum_net_profit DESC) AS profit_rank
FROM joined_data
ORDER BY d_year, profit_rank
LIMIT 100
