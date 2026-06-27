WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_brand, d.d_year, d.d_month_seq
)
SELECT
    s.i_category,
    s.i_brand,
    s.d_year,
    s.d_month_seq,
    s.total_quantity,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE WHEN s.total_orders > 0 THEN COALESCE(r.total_returns, 0) * 1.0 / s.total_orders ELSE 0 END AS return_rate,
    CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amount, 0) * 1.0 / s.total_sales ELSE 0 END AS return_amount_ratio
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
    AND s.i_brand = r.i_brand
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year, s.d_month_seq, s.total_sales DESC
LIMIT 100
