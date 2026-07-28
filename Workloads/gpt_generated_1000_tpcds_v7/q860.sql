WITH daily_agg AS (
    SELECT
        d.d_date AS date_key,
        SUM(cs.cs_ext_sales_price) AS daily_sales,
        SUM(cs.cs_ext_discount_amt) AS daily_discount,
        SUM(wr.wr_return_amt_inc_tax) AS daily_returns,
        SUM(wr.wr_net_loss) AS daily_return_loss
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        cs.cs_ext_discount_amt > 500
        AND cs.cs_wholesale_cost BETWEEN 10 AND 100
        AND cs.cs_quantity > 2
        AND d.d_qoy = 2
        AND d.d_current_day = 'N'
        AND d.d_year = 2001
        AND wr.wr_return_amt_inc_tax > 1000
        AND wr.wr_returning_hdemo_sk IN (1690, 3840)
    GROUP BY d.d_date
)
SELECT
    AVG(daily_sales) AS avg_daily_sales,
    AVG(daily_returns) AS avg_daily_returns,
    AVG(daily_sales - daily_returns) AS avg_daily_net,
    SUM(CASE WHEN daily_sales > 10000 THEN 1 ELSE 0 END) AS high_sales_days
FROM daily_agg
WHERE daily_discount < 2000
HAVING AVG(daily_sales) > 5000
ORDER BY avg_daily_net DESC
LIMIT 100
