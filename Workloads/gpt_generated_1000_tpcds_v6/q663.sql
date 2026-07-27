WITH filtered_dates AS (
    SELECT
        d.d_date_sk,
        d.d_day_name,
        d.d_year,
        d.d_month_seq,
        CONCAT(d.d_day_name, '_', CAST(d.d_year AS varchar)) AS day_year_key
    FROM date_dim d
    WHERE regexp_like(d.d_day_name, '^S')
      AND d.d_day_name LIKE '%day%'
)
SELECT
    fd.d_day_name,
    fd.day_year_key,
    fd.d_year,
    fd.d_month_seq,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS sales_orders,
    COUNT(DISTINCT wr.wr_order_number) AS return_orders
FROM filtered_dates fd
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = fd.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = fd.d_date_sk
GROUP BY
    fd.d_day_name,
    fd.day_year_key,
    fd.d_year,
    fd.d_month_seq
HAVING
    SUM(cs.cs_net_profit) > 10000
    AND SUM(wr.wr_net_loss) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
