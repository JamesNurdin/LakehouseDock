WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        s.web_name,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY w.w_warehouse_name, s.web_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        w.w_warehouse_name,
        s.web_name,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY w.w_warehouse_name, s.web_name, d.d_year, d.d_month_seq
)
SELECT
    s.w_warehouse_name,
    s.web_name,
    s.d_year,
    s.d_month_seq,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_sales_amount,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.w_warehouse_name = r.w_warehouse_name
    AND s.web_name = r.web_name
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.w_warehouse_name, s.web_name, s.d_year, s.d_month_seq
