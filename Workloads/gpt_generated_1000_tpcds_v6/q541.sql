WITH sales_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count,
        td.t_hour,
        td.t_minute,
        td.t_meal_time
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE cd.cd_education_status IN ('Advanced Degree', '4 yr Degree')
      AND cd.cd_dep_employed_count >= 1
      AND cd.cd_purchase_estimate BETWEEN 2000 AND 8000
      AND td.t_hour BETWEEN 9 AND 17
      AND td.t_meal_time = 'Lunch'
),
agg_sales AS (
    SELECT
        cd_gender,
        cd_education_status,
        t_hour,
        COUNT(*) AS transaction_cnt,
        SUM(ss_sales_price * ss_quantity) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        MIN(ss_sales_price) AS min_price,
        MAX(ss_sales_price) AS max_price
    FROM sales_joined
    GROUP BY cd_gender, cd_education_status, t_hour
)
SELECT
    cd_gender,
    cd_education_status,
    t_hour,
    transaction_cnt,
    total_sales,
    avg_profit,
    min_price,
    max_price,
    SUM(total_sales) OVER (
        PARTITION BY cd_gender
        ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_gender
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
