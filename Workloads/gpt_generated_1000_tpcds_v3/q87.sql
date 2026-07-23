WITH
    store_agg AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            ca.ca_country AS ca_country,
            SUM(ss.ss_net_paid) AS total_store_net_paid,
            SUM(ss.ss_net_profit) AS total_store_net_profit,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt
        FROM
            store_sales ss
            JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
            JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
            JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
            LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                AND sr.sr_customer_sk = c.c_customer_sk
                AND sr.sr_addr_sk = ca.ca_address_sk
                AND sr.sr_item_sk = ss.ss_item_sk
            LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                AND ws.ws_bill_addr_sk = ca.ca_address_sk
                AND ws.ws_sold_time_sk = t_s.t_time_sk
        WHERE
            ca.ca_country = 'United States'
            AND t_s.t_hour BETWEEN 9 AND 17
            AND ss.ss_quantity > 1
        GROUP BY
            c.c_customer_sk,
            c.c_customer_id,
            ca.ca_country
    ),
    web_agg AS (
        SELECT
            c.c_customer_sk,
            SUM(ws.ws_net_paid_inc_ship) AS total_web_net_paid,
            SUM(ws.ws_net_profit) AS total_web_net_profit,
            COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
            sm.sm_code
        FROM
            web_sales ws
            JOIN time_dim t_w ON ws.ws_sold_time_sk = t_w.t_time_sk
            JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
            JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
            JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE
            ca.ca_country = 'United States'
            AND t_w.t_hour BETWEEN 9 AND 17
            AND sm.sm_code = 'AIR'
        GROUP BY
            c.c_customer_sk,
            sm.sm_code
    ),
    return_agg AS (
        SELECT
            c.c_customer_sk,
            SUM(sr.sr_net_loss) AS total_return_loss
        FROM
            store_returns sr
            JOIN time_dim t_r ON sr.sr_return_time_sk = t_r.t_time_sk
            JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
            JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE
            ca.ca_country = 'United States'
            AND t_r.t_hour BETWEEN 9 AND 17
        GROUP BY
            c.c_customer_sk
    )
SELECT
    s.c_customer_id,
    s.ca_country,
    s.total_store_net_paid,
    COALESCE(w.total_web_net_paid, 0) AS total_web_net_paid,
    s.total_store_net_profit,
    COALESCE(w.total_web_net_profit, 0) AS total_web_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_store_net_paid + COALESCE(w.total_web_net_paid, 0) - COALESCE(r.total_return_loss, 0)) AS net_revenue,
    ROW_NUMBER() OVER (ORDER BY (s.total_store_net_paid + COALESCE(w.total_web_net_paid, 0) - COALESCE(r.total_return_loss, 0)) DESC) AS revenue_rank,
    (
        SELECT AVG(inner_s.total_store_net_paid + COALESCE(inner_w.total_web_net_paid, 0) - COALESCE(inner_r.total_return_loss, 0))
        FROM store_agg inner_s
        LEFT JOIN web_agg inner_w ON inner_s.c_customer_sk = inner_w.c_customer_sk
        LEFT JOIN return_agg inner_r ON inner_s.c_customer_sk = inner_r.c_customer_sk
    ) AS avg_net_revenue
FROM
    store_agg s
    LEFT JOIN web_agg w ON s.c_customer_sk = w.c_customer_sk
    LEFT JOIN return_agg r ON s.c_customer_sk = r.c_customer_sk
WHERE
    (s.total_store_net_paid + COALESCE(w.total_web_net_paid, 0) - COALESCE(r.total_return_loss, 0)) > (
        SELECT AVG(inner2_s.total_store_net_paid + COALESCE(inner2_w.total_web_net_paid, 0) - COALESCE(inner2_r.total_return_loss, 0))
        FROM store_agg inner2_s
        LEFT JOIN web_agg inner2_w ON inner2_s.c_customer_sk = inner2_w.c_customer_sk
        LEFT JOIN return_agg inner2_r ON inner2_s.c_customer_sk = inner2_r.c_customer_sk
    )
ORDER BY
    net_revenue DESC
LIMIT 100
