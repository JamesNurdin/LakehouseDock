WITH store_sales_agg AS (
    SELECT
        date_trunc('month', d_s.d_date) AS month,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS sales_net_paid,
        SUM(sr.sr_net_loss) AS returns_net_loss,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d_s.d_year = 2000
    GROUP BY date_trunc('month', d_s.d_date), i.i_category
),
catalog_sales_agg AS (
    SELECT
        date_trunc('month', d_c.d_date) AS month,
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS sales_net_paid,
        SUM(cr.cr_net_loss) AS returns_net_loss,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d_c ON cs.cs_sold_date_sk = d_c.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d_c.d_year = 2000
    GROUP BY date_trunc('month', d_c.d_date), i.i_category
),
web_sales_agg AS (
    SELECT
        date_trunc('month', d_w.d_date) AS month,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS sales_net_paid,
        SUM(wr.wr_net_loss) AS returns_net_loss,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d_w ON ws.ws_sold_date_sk = d_w.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d_w.d_year = 2000
    GROUP BY date_trunc('month', d_w.d_date), i.i_category
),
combined AS (
    SELECT month, category, sales_net_paid, returns_net_loss, net_profit FROM store_sales_agg
    UNION ALL
    SELECT month, category, sales_net_paid, returns_net_loss, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT month, category, sales_net_paid, returns_net_loss, net_profit FROM web_sales_agg
)
SELECT
    month,
    category,
    SUM(sales_net_paid) - COALESCE(SUM(returns_net_loss), 0) AS total_net_revenue,
    SUM(net_profit) AS total_net_profit
FROM combined
GROUP BY month, category
ORDER BY month, category
