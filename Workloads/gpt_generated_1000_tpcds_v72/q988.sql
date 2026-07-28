WITH web_profit AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_amount,
        CAST('web' AS VARCHAR) AS source
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    GROUP BY w.w_warehouse_id
),
catalog_profit AS (
    SELECT
        w.w_warehouse_id,
        SUM(cr.cr_net_loss) * -1 AS total_amount,
        CAST('catalog' AS VARCHAR) AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    GROUP BY w.w_warehouse_id
)
SELECT * FROM web_profit
UNION ALL
SELECT * FROM catalog_profit
ORDER BY total_amount DESC
LIMIT 100
