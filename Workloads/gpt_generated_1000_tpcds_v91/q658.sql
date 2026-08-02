WITH aggregated_sales AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        MAX(cd.cd_dep_college_count) AS max_dep_college_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
        ON cd.cd_demo_sk = wr.wr_returning_cdemo_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ss.ss_net_paid > 0
      AND ss.ss_net_paid < 10000
      AND cd.cd_dep_count >= 1
      AND cd.cd_gender IN ('M', 'F')
      AND ss.ss_coupon_amt <= 1500
    GROUP BY cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ss.ss_net_profit) > 500
),
unioned_sales AS (
    SELECT
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        total_net_profit,
        sales_cnt,
        max_dep_college_cnt,
        CASE WHEN total_net_profit / sales_cnt > 500 THEN 'HIGH' ELSE 'LOW' END AS profit_level
    FROM aggregated_sales
    WHERE NOT EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        JOIN web_returns wr2 ON cd2.cd_demo_sk = wr2.wr_returning_cdemo_sk
        WHERE cd2.cd_gender = aggregated_sales.cd_gender
          AND cd2.cd_marital_status = aggregated_sales.cd_marital_status
    )
    UNION
    SELECT
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        total_net_profit,
        sales_cnt,
        max_dep_college_cnt,
        CASE WHEN total_net_profit / sales_cnt > 500 THEN 'HIGH' ELSE 'LOW' END AS profit_level
    FROM aggregated_sales
    WHERE max_dep_college_cnt >= 2
)
SELECT
    gender,
    marital_status,
    AVG(total_net_profit) AS avg_total_net_profit,
    AVG(sales_cnt) AS avg_sales_cnt,
    profit_level
FROM unioned_sales
GROUP BY gender, marital_status, profit_level
ORDER BY avg_total_net_profit DESC
