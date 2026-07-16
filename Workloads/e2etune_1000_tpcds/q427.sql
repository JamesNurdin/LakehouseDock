WITH sales_agg AS (
    SELECT
        ds.d_fy_year,
        ds.d_fy_quarter_seq,
        ds.d_month_seq,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_quantity) AS total_qty_sold,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN time_dim ts ON ws.ws_sold_time_sk = ts.t_time_sk
    WHERE ts.t_shift = 'Morning'
    GROUP BY ds.d_fy_year, ds.d_fy_quarter_seq, ds.d_month_seq
    HAVING ds.d_fy_year = 1902
),
returns_agg AS (
    SELECT
        dr.d_fy_year,
        dr.d_fy_quarter_seq,
        dr.d_month_seq,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_qty_returned
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    GROUP BY dr.d_fy_year, dr.d_fy_quarter_seq, dr.d_month_seq
    HAVING dr.d_fy_year = 1902
)
SELECT
    COALESCE(sa.d_fy_year, ra.d_fy_year) AS fiscal_year,
    COALESCE(sa.d_fy_quarter_seq, ra.d_fy_quarter_seq) AS fiscal_quarter,
    COALESCE(sa.d_month_seq, ra.d_month_seq) AS month_seq,
    COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
    COALESCE(sa.total_qty_sold, 0) - COALESCE(ra.total_qty_returned, 0) AS net_quantity,
    COALESCE(sa.total_discount, 0) AS total_discount,
    COALESCE(sa.avg_discount, 0) AS avg_discount
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.d_fy_year = ra.d_fy_year
   AND sa.d_fy_quarter_seq = ra.d_fy_quarter_seq
   AND sa.d_month_seq = ra.d_month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 100
