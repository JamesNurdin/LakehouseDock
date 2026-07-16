WITH profit_by_demo AS (
    SELECT
        cd.cd_education_status,
        hd.hd_vehicle_count,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_net_paid) AS total_revenue,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2452000 AND 2453000
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'Medium'
    GROUP BY cd.cd_education_status, hd.hd_vehicle_count
    HAVING SUM(ss.ss_net_profit) > 2000
)
SELECT
    cd_education_status,
    hd_vehicle_count,
    total_profit,
    total_revenue,
    avg_discount,
    sales_cnt,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_demo
ORDER BY profit_rank
LIMIT 10
