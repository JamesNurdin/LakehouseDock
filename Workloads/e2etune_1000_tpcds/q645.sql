WITH sales_cp AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_number,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items
    FROM store_sales ss
    JOIN catalog_page cp
        ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_department = 'DEPARTMENT'
      AND ss.ss_sold_date_sk >= 2450800
      AND ss.ss_sold_date_sk <= 2451100
    GROUP BY cp.cp_department, cp.cp_type, cp.cp_catalog_number
)
SELECT
    cp_department,
    cp_type,
    cp_catalog_number,
    total_net_paid,
    total_profit,
    avg_discount,
    total_quantity,
    distinct_items,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_cp
ORDER BY profit_rank
LIMIT 10
