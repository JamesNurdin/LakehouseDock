WITH sales_returns AS (
    SELECT
        wp.wp_type,
        d_sold.d_year,
        d_sold.d_month_seq,
        ws.ws_net_profit,
        wr.wr_net_loss
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
        AND wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE d_sold.d_date >= DATE '2001-01-01'
      AND d_sold.d_date < DATE '2002-01-01'
),
monthly_profit AS (
    SELECT
        wp_type,
        d_year,
        d_month_seq,
        SUM(ws_net_profit) AS total_sales_profit,
        SUM(COALESCE(wr_net_loss, 0)) AS total_return_loss,
        SUM(ws_net_profit) - SUM(COALESCE(wr_net_loss, 0)) AS net_profit_after_returns
    FROM sales_returns
    GROUP BY wp_type, d_year, d_month_seq
)
SELECT
    wp_type,
    d_year,
    d_month_seq,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns,
    SUM(net_profit_after_returns) OVER (PARTITION BY wp_type ORDER BY d_year, d_month_seq) AS cumulative_net_profit
FROM monthly_profit
ORDER BY wp_type, d_year, d_month_seq
