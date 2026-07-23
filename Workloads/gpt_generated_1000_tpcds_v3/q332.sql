WITH sales_by_site AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        d_sales.d_year AS d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS transaction_count,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_sales.d_year BETWEEN 2000 AND 2002
      AND t.t_sub_shift = 'morning'
      AND ws.web_state = 'TX'
      AND ss.ss_ext_discount_amt > 500
    GROUP BY ws.web_site_sk, ws.web_name, d_sales.d_year
    HAVING SUM(ss.ss_ext_sales_price) > 20000
)
SELECT
    web_site_sk,
    web_name,
    d_year,
    total_sales,
    total_profit,
    transaction_count,
    CASE WHEN total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM sales_by_site
ORDER BY d_year, sales_rank
