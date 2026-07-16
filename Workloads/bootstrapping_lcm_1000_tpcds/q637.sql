WITH ws_daily AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_ship_date_sk AS ship_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS num_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk, ws.ws_sold_date_sk, ws.ws_ship_date_sk
),
cr_daily AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk AS return_date_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_fee) AS total_return_fee
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk, cr.cr_returned_date_sk
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    w.w_state,
    w.w_city,
    s.s_state AS store_state,
    s.s_city AS store_city,
    ws_daily.total_sales,
    ws_daily.total_profit,
    ws_daily.total_quantity,
    ws_daily.num_sales,
    COALESCE(cr_daily.total_return_loss, 0) AS total_return_loss,
    COALESCE(cr_daily.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr_daily.total_return_fee, 0) AS total_return_fee,
    ws_daily.total_sales - COALESCE(cr_daily.total_return_loss, 0) AS net_sales_after_returns,
    CASE
        WHEN ws_daily.total_sales = 0 THEN NULL
        ELSE (COALESCE(cr_daily.total_return_loss, 0) / ws_daily.total_sales) * 100
    END AS return_loss_pct,
    RANK() OVER (PARTITION BY d_sold.d_year, d_sold.d_month_seq ORDER BY ws_daily.total_profit DESC) AS profit_rank_month
FROM ws_daily
JOIN date_dim d_sold ON ws_daily.sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws_daily.ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON ws_daily.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN cr_daily ON cr_daily.cr_warehouse_sk = w.w_warehouse_sk
    AND cr_daily.return_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2021
ORDER BY net_sales_after_returns DESC
LIMIT 100
