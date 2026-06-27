WITH sales_by_site_date AS (
    SELECT
        ws.ws_web_site_sk,
        d.d_date,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_web_site_sk, d.d_date
),
returns_by_site_date AS (
    SELECT
        ws.ws_web_site_sk,
        d.d_date,
        SUM(wr.wr_return_quantity) AS total_quantity_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_web_site_sk, d.d_date
),
inventory_by_date AS (
    SELECT
        d.d_date,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
)
SELECT
    ws_site.web_name,
    DATE_TRUNC('month', sbd.d_date) AS month,
    SUM(sbd.total_quantity_sold) AS total_quantity_sold,
    SUM(COALESCE(rbd.total_quantity_returned, 0)) AS total_quantity_returned,
    SUM(sbd.total_sales_amount) AS total_sales_amount,
    SUM(COALESCE(rbd.total_return_amount, 0)) AS total_return_amount,
    SUM(sbd.total_net_profit) - SUM(COALESCE(rbd.total_return_loss, 0)) AS net_profit_after_returns,
    AVG(iqd.total_inventory_on_hand) AS avg_inventory_on_hand
FROM sales_by_site_date sbd
LEFT JOIN returns_by_site_date rbd
    ON sbd.ws_web_site_sk = rbd.ws_web_site_sk
    AND sbd.d_date = rbd.d_date
LEFT JOIN inventory_by_date iqd
    ON sbd.d_date = iqd.d_date
JOIN web_site ws_site
    ON sbd.ws_web_site_sk = ws_site.web_site_sk
GROUP BY ws_site.web_name, DATE_TRUNC('month', sbd.d_date)
ORDER BY ws_site.web_name, month
