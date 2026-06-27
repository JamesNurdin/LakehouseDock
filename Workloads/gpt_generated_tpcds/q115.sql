WITH sales_by_store_hour_gender AS (
    SELECT
        s.s_store_name,
        t.t_hour,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_count,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_name, t.t_hour, cd.cd_gender
)
SELECT
    s_store_name,
    t_hour,
    cd_gender,
    total_sales,
    total_discount,
    total_profit,
    transaction_count,
    avg_sales_price
FROM sales_by_store_hour_gender
ORDER BY total_sales DESC
LIMIT 200
