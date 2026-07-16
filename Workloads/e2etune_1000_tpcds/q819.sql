WITH latest_fy AS (
    SELECT max(d_fy_year) AS fy_year FROM date_dim
),
filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        cd.cd_demo_sk,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        w.w_state
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN latest_fy lf
    WHERE cd.cd_purchase_estimate >= 1500
      AND cd.cd_credit_rating = 'Good'
      AND d.d_fy_year = lf.fy_year
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    CROSS JOIN latest_fy lf
    WHERE d.d_fy_year = lf.fy_year
    GROUP BY wr.wr_order_number
)
SELECT
    fs.w_warehouse_name,
    fs.d_year,
    fs.d_month_seq,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    SUM(fs.ws_net_profit) AS total_profit,
    COALESCE(SUM(r.total_return_amount), 0) AS total_returns,
    COUNT(DISTINCT fs.ws_order_number) AS num_orders,
    COUNT(DISTINCT r.wr_order_number) AS num_returned_orders,
    CASE WHEN SUM(fs.ws_ext_sales_price) = 0 THEN 0
         ELSE COALESCE(SUM(r.total_return_amount), 0) / SUM(fs.ws_ext_sales_price)
    END AS return_rate,
    RANK() OVER (PARTITION BY fs.d_year ORDER BY SUM(fs.ws_net_profit) DESC) AS profit_rank
FROM filtered_sales fs
LEFT JOIN returns_agg r ON fs.ws_order_number = r.wr_order_number
GROUP BY fs.w_warehouse_name, fs.d_year, fs.d_month_seq
HAVING SUM(fs.ws_ext_sales_price) > 10000
ORDER BY fs.d_year DESC, fs.d_month_seq, total_profit DESC
LIMIT 100
