WITH sales_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        cp.cp_start_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        CASE WHEN cp.cp_type = 'monthly' THEN 'M' ELSE 'O' END AS type_flag
    FROM (
        SELECT cs.*
        FROM catalog_sales cs
        WHERE cs.cs_ext_ship_cost > 500
          AND cs.cs_ship_cdemo_sk IN (
              SELECT cs2.cs_ship_cdemo_sk
              FROM catalog_sales cs2
              WHERE cs2.cs_ext_ship_cost > 1000
              GROUP BY cs2.cs_ship_cdemo_sk
              HAVING COUNT(*) > 5
          )
          AND cs.cs_sold_date_sk BETWEEN 2451000 AND 2451500
    ) cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk >= 2451055
    GROUP BY cp.cp_department, cp.cp_type, cp.cp_start_date_sk
    HAVING SUM(cs.cs_ext_sales_price) > 10000
)
SELECT
    cp_department,
    type_flag,
    cp_start_date_sk,
    total_sales,
    avg_profit,
    sales_cnt,
    distinct_items,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_sales DESC) AS dept_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
