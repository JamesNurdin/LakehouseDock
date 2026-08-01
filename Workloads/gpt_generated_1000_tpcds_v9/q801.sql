WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_list_price,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        ss.ss_ext_list_price,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        CASE 
            WHEN ss.ss_quantity > 5 THEN 'Bulk'
            ELSE 'Regular'
        END AS purchase_type
    FROM store_sales AS ss
    JOIN customer_demographics AS cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_list_price > 20
      AND ss.ss_quantity >= 1
      AND ss.ss_store_sk IN (88, 49, 805)
      AND ss.ss_ext_sales_price BETWEEN 1000 AND 5000
      AND cd.cd_gender = 'M'
      AND cd.cd_marital_status IN ('M', 'S')
      AND cd.cd_dep_employed_count >= 2
),
aggregated AS (
    SELECT
        ss_store_sk,
        cd_marital_status,
        cd_gender,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_list_price) AS avg_list_price,
        COUNT(*) AS transaction_count
    FROM filtered_sales
    GROUP BY ss_store_sk, cd_marital_status, cd_gender
)
SELECT
    ss_store_sk,
    cd_marital_status,
    cd_gender,
    total_net_paid,
    total_quantity,
    avg_list_price,
    transaction_count,
    ROW_NUMBER() OVER (PARTITION BY cd_marital_status ORDER BY total_net_paid DESC) AS rn_by_marital_status,
    RANK() OVER (ORDER BY total_net_paid DESC) AS overall_rank,
    CASE
        WHEN total_net_paid >= 20000 THEN 'High'
        WHEN total_net_paid >= 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM aggregated
WHERE transaction_count >= 5
ORDER BY total_net_paid DESC, ss_store_sk
LIMIT 100
