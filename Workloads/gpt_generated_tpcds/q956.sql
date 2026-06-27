WITH store_sales_monthly AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_monthly AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, ws.ws_web_site_sk
),
combined AS (
    SELECT 
        ws_month.d_year,
        ws_month.d_month_seq,
        ws_month.ws_web_site_sk,
        ws_month.total_net_paid_inc_tax,
        ws_month.total_net_profit,
        ws_month.total_return_net_loss,
        COALESCE(ss_month.store_net_profit, 0) AS store_net_profit
    FROM web_sales_monthly ws_month
    LEFT JOIN store_sales_monthly ss_month
        ON ws_month.d_year = ss_month.d_year
        AND ws_month.d_month_seq = ss_month.d_month_seq
)
SELECT 
    c.d_year,
    c.d_month_seq,
    ws.web_name,
    c.total_net_paid_inc_tax,
    c.total_net_profit,
    c.total_return_net_loss,
    c.store_net_profit,
    (c.total_net_paid_inc_tax - c.total_return_net_loss) AS net_revenue_after_returns
FROM combined c
JOIN web_site ws
    ON c.ws_web_site_sk = ws.web_site_sk
ORDER BY c.d_year, c.d_month_seq, ws.web_name
