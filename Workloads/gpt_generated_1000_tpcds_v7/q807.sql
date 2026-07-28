WITH sales_join AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        d.d_year,
        d.d_quarter_name,
        d.d_qoy,
        t.t_hour,
        w.web_state,
        w.web_gmt_offset
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND t.t_hour BETWEEN 9 AND 17
      AND w.web_gmt_offset = -6.00
)
SELECT
    d_year,
    d_quarter_name,
    t_hour,
    web_state,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers,
    MIN(ss_ext_sales_price) AS min_sale,
    MAX(ss_ext_sales_price) AS max_sale
FROM sales_join
GROUP BY d_year, d_quarter_name, t_hour, web_state
ORDER BY total_sales DESC
LIMIT 20
