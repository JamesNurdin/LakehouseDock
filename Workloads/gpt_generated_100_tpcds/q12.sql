WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity AS sales_quantity,
        ws.ws_net_profit AS sales_net_profit
    FROM web_sales ws
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM web_returns wr
)
SELECT
    ws_site.web_name,
    d_sold.d_year,
    d_sold.d_moy,
    SUM(s.sales_quantity) AS total_sales_quantity,
    SUM(s.sales_net_profit) AS total_sales_net_profit,
    SUM(r.wr_return_quantity) AS total_return_quantity,
    SUM(r.wr_net_loss) AS total_return_net_loss,
    SUM(s.sales_net_profit) - COALESCE(SUM(r.wr_net_loss), 0) AS net_profit_after_returns,
    CASE
        WHEN SUM(s.sales_quantity) = 0 THEN 0
        ELSE SUM(r.wr_return_quantity) / CAST(SUM(s.sales_quantity) AS double)
    END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
JOIN date_dim d_sold
    ON s.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site ws_site
    ON s.ws_web_site_sk = ws_site.web_site_sk
GROUP BY ws_site.web_name, d_sold.d_year, d_sold.d_moy
ORDER BY ws_site.web_name, d_sold.d_year, d_sold.d_moy
