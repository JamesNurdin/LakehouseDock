WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_type,
        cs.cs_sold_date_sk,
        cs.cs_coupon_amt,
        cs.cs_ext_tax,
        cs.cs_ext_ship_cost,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Books'
      AND cp.cp_catalog_number IN (1, 7, 14)
      AND cs.cs_coupon_amt > 100
      AND cs.cs_ext_tax < 100
      AND cs.cs_ext_ship_cost BETWEEN 200 AND 2000
),
aggregated AS (
    SELECT
        cp_department,
        cp_catalog_number,
        cp_type,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_coupon_amt) AS avg_coupon,
        SUM(cs_quantity) AS total_quantity,
        MIN(cs_ext_tax) AS min_tax,
        MAX(cs_ext_tax) AS max_tax,
        COUNT(*) AS transaction_count,
        SUM(cs_net_profit) AS total_profit
    FROM page_sales
    GROUP BY cp_department, cp_catalog_number, cp_type
)
SELECT
    cp_department,
    cp_catalog_number,
    cp_type,
    total_sales,
    avg_coupon,
    total_quantity,
    min_tax,
    max_tax,
    transaction_count,
    total_profit,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        cp_department,
        cp_catalog_number,
        cp_type,
        total_sales,
        avg_coupon,
        total_quantity,
        min_tax,
        max_tax,
        transaction_count,
        total_profit
    FROM aggregated
    WHERE cp_type = 'A'
    UNION ALL
    SELECT
        cp_department,
        cp_catalog_number,
        cp_type,
        total_sales,
        avg_coupon,
        total_quantity,
        min_tax,
        max_tax,
        transaction_count,
        total_profit
    FROM aggregated
    WHERE cp_type = 'B'
) AS combined
ORDER BY cp_department, profit_rank, total_sales DESC
LIMIT 100
