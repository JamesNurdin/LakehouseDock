WITH sales_by_hour AS (
    SELECT
        td.t_hour,
        td.t_shift,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour, td.t_shift
),
returns_by_hour AS (
    SELECT
        td.t_hour,
        td.t_shift,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour, td.t_shift
)
SELECT
    s.t_hour,
    s.t_shift,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_margin,
    s.total_discount / NULLIF(s.sales_cnt, 0) AS avg_discount_per_sale
FROM sales_by_hour s
LEFT JOIN returns_by_hour r
    ON s.t_hour = r.t_hour AND s.t_shift = r.t_shift
WHERE s.total_sales_profit > 5000
ORDER BY net_margin DESC
LIMIT 100
