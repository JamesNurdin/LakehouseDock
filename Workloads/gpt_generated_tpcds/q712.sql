WITH agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(CASE WHEN wp.wp_customer_sk = c.c_customer_sk THEN ws.ws_net_profit ELSE 0 END) AS profit_on_own_pages,
        SUM(CASE WHEN wp.wp_customer_sk <> c.c_customer_sk THEN ws.ws_net_profit ELSE 0 END) AS profit_on_other_pages
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_net_paid > 0
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        wp.wp_type
)
SELECT
    agg.c_customer_sk,
    agg.c_first_name,
    agg.c_last_name,
    agg.wp_type,
    agg.orders,
    agg.total_net_paid,
    agg.total_net_profit,
    agg.profit_on_own_pages,
    agg.profit_on_other_pages,
    RANK() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank_overall,
    (agg.total_net_profit / SUM(agg.total_net_profit) OVER ()) * 100 AS profit_percent_of_total
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 10
