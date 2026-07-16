WITH sales_cd_hd AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_buy_potential,
        hd.hd_vehicle_count
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2458840 AND 2458949  -- example range for Q1 2022
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential = 'High'
)
SELECT
    cd_gender,
    hd_vehicle_count,
    COUNT(*) AS sales_transactions,
    SUM(ss_ext_sales_price) AS total_sales_amount,
    AVG(ss_net_profit) AS avg_profit_per_sale,
    SUM(ss_net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM sales_cd_hd
GROUP BY cd_gender, hd_vehicle_count
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
