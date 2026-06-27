WITH sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date <= DATE '2002-12-31'
    GROUP BY i.i_category, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date <= DATE '2002-12-31'
    GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT
    s.i_category,
    s.d_year,
    s.d_moy AS month,
    s.total_sales,
    s.total_profit,
    s.total_qty,
    s.total_discount,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE WHEN s.total_qty = 0 THEN 0 ELSE COALESCE(r.total_returns, 0) * 1.0 / s.total_qty END AS return_rate,
    CASE WHEN s.total_qty = 0 THEN 0 ELSE s.total_discount * 1.0 / s.total_qty END AS avg_discount_per_unit,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
   AND s.d_year = r.d_year
   AND s.d_moy = r.d_moy
ORDER BY s.total_profit DESC
LIMIT 20
