-- Total net profit, sales and average discount by warehouse, catalog department and customer gender
WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        cp.cp_department,
        cd.cd_gender,
        SUM(cs.cs_net_profit)            AS total_profit,
        SUM(cs.cs_ext_sales_price)       AS total_sales,
        AVG(cs.cs_ext_discount_amt)      AS avg_discount,
        COUNT(*)                         AS order_count
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 0
    GROUP BY
        w.w_warehouse_name,
        cp.cp_department,
        cd.cd_gender
)
SELECT *
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
