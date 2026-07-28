WITH
    sales AS (
        SELECT
            d.d_date AS trans_date,
            t.t_hour AS trans_hour,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit,
            CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'M'
        GROUP BY ROLLUP (d.d_date, t.t_hour)
    ),
    returns AS (
        SELECT
            d.d_date AS trans_date,
            t.t_hour AS trans_hour,
            -SUM(sr.sr_return_amt) AS total_sales,
            -SUM(sr.sr_net_loss) AS total_profit,
            CASE WHEN SUM(sr.sr_net_loss) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'M'
        GROUP BY ROLLUP (d.d_date, t.t_hour)
    ),
    combined AS (
        SELECT * FROM sales
        UNION ALL
        SELECT * FROM returns
    )
SELECT
    trans_date,
    trans_hour,
    profit_category,
    total_sales,
    total_profit,
    SUM(total_sales) OVER (
        PARTITION BY profit_category
        ORDER BY trans_date, trans_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales,
    SUM(total_profit) OVER (
        PARTITION BY profit_category
        ORDER BY trans_date, trans_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_profit
FROM combined
ORDER BY trans_date NULLS LAST, trans_hour NULLS LAST, profit_category
