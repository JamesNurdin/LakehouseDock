WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        sd.d_year AS sales_year,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN date_dim sd
        ON ws.ws_sold_date_sk = sd.d_date_sk
    WHERE sd.d_date >= DATE '2022-01-01'
      AND sd.d_date < DATE '2023-01-01'
),
returns_data AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_order_number
)
SELECT
    ws_data.sales_year,
    ws_data.ws_web_site_sk,
    wsite.web_name,
    ws_data.ws_ship_mode_sk,
    sm.sm_type,
    SUM(ws_data.ws_ext_sales_price) AS total_sales,
    SUM(ws_data.ws_ext_discount_amt) AS total_discount,
    SUM(ws_data.ws_net_profit) AS total_profit,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    SUM(ws_data.ws_net_profit) - COALESCE(SUM(r.total_return_loss), 0) AS net_profit_after_returns
FROM sales_data ws_data
LEFT JOIN returns_data r
    ON ws_data.ws_order_number = r.wr_order_number
JOIN web_site wsite
    ON ws_data.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm
    ON ws_data.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY ws_data.sales_year,
         ws_data.ws_web_site_sk,
         wsite.web_name,
         ws_data.ws_ship_mode_sk,
         sm.sm_type
ORDER BY ws_data.sales_year DESC,
         total_sales DESC
LIMIT 20
