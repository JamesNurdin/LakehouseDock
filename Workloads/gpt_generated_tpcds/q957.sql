WITH agg AS (
    SELECT
        ca.ca_country AS country,
        r.r_reason_desc AS return_reason,
        td.t_hour AS return_hour,
        wp.wp_type AS page_type,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_sales_net_profit
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY ca.ca_country, r.r_reason_desc, td.t_hour, wp.wp_type
)
SELECT
    country,
    return_reason,
    return_hour,
    page_type,
    distinct_return_orders,
    total_return_quantity,
    total_return_amount,
    total_net_loss,
    total_sales_amount,
    total_sales_quantity,
    total_sales_net_profit,
    SUM(total_return_amount) OVER (
        PARTITION BY country, return_reason
        ORDER BY return_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
