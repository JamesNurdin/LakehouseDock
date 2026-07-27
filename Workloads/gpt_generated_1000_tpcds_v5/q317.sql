WITH cs_cd AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_college_count
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND cd.cd_dep_college_count >= 2
      AND sm.sm_type = 'AIR'
)
SELECT
    cd_gender,
    cd_marital_status,
    COUNT(*) AS orders_cnt,
    SUM(cs_quantity) AS total_qty,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    MIN(cs_net_profit) AS min_profit,
    MAX(cs_net_profit) AS max_profit
FROM cs_cd
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_cdemo_sk = cs_cd.cs_ship_cdemo_sk
      AND sr.sr_return_amt > 100
      AND sr.sr_fee < 50
)
GROUP BY cd_gender, cd_marital_status
ORDER BY total_sales DESC
LIMIT 100
