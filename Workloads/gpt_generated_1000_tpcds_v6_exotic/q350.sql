WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 30
      AND ss.ss_net_profit > 0
      AND cd.cd_purchase_estimate BETWEEN 3000 AND 8000
      AND cd.cd_education_status IN ('4 yr Degree', 'College')
)
SELECT DISTINCT
    fs.cd_gender,
    fs.cd_education_status,
    fs.cd_purchase_estimate,
    fs.ss_item_sk,
    fs.ss_quantity,
    fs.ss_sales_price,
    fs.ss_net_profit,
    CASE
        WHEN fs.cd_dep_count = 0 THEN 'NoDependents'
        WHEN fs.cd_dep_count <= 2 THEN 'FewDependents'
        ELSE 'ManyDependents'
    END AS dep_category,
    RANK() OVER (PARTITION BY fs.cd_gender ORDER BY fs.ss_net_profit DESC) AS profit_rank_gender
FROM filtered_sales fs
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = fs.ss_item_sk
      AND ss2.ss_net_profit > fs.ss_net_profit
)
ORDER BY profit_rank_gender ASC, fs.ss_net_profit DESC
LIMIT 100
