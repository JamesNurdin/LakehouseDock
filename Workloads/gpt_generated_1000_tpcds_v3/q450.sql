WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        w.web_site_sk,
        w.web_name,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_paid,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions,
        SUM(ws.ws_quantity) AS web_total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_orders
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
        AND w.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND t.t_hour BETWEEN 9 AND 17
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '10000+'
        AND s.s_state = 'CA'
        AND w.web_class = 'A'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        w.web_site_sk,
        w.web_name
)
SELECT
    b.s_store_sk AS store_sk,
    b.s_store_name AS store_name,
    b.s_state AS state,
    b.web_site_sk,
    b.web_name,
    b.store_net_paid,
    b.store_net_loss,
    b.web_net_paid,
    (b.store_net_paid - b.store_net_loss + b.web_net_paid) AS combined_net_profit,
    CASE
        WHEN (b.store_net_paid - b.store_net_loss + b.web_net_paid) > (
            SELECT AVG(store_net_paid - store_net_loss + web_net_paid) FROM base
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    RANK() OVER (ORDER BY (b.store_net_paid - b.store_net_loss + b.web_net_paid) DESC) AS profit_rank
FROM base b
ORDER BY profit_rank
LIMIT 100
