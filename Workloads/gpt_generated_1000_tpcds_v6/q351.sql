WITH joined_data AS (
    SELECT
        c.c_customer_id,
        CASE WHEN td.t_hour < 12 THEN 'Morning' ELSE 'Afternoon' END AS day_part,
        ws.ws_net_profit,
        sr.sr_net_loss,
        ws.ws_order_number,
        sr.sr_ticket_number
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN web_page
        ON ws.ws_web_page_sk = web_page.wp_web_page_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND w.w_country = 'United States'
      AND web_site.web_site_id = 'AAAAAAAABAAAAAA'
      AND c.c_birth_year BETWEEN 1970 AND 1985
),
aggregated AS (
    SELECT
        c_customer_id,
        day_part,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(sr_net_loss) AS total_store_loss,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        COUNT(sr_ticket_number) AS total_returns
    FROM joined_data
    GROUP BY c_customer_id, day_part
)
SELECT
    c_customer_id,
    day_part,
    total_web_profit,
    total_store_loss,
    web_orders,
    total_returns,
    SUM(total_web_profit) OVER (
        PARTITION BY day_part
        ORDER BY total_web_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_profit_by_part
FROM aggregated
ORDER BY total_web_profit DESC
LIMIT 100
