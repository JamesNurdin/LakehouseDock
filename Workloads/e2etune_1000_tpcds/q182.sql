WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_catalog_page_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
      AND cs.cs_ext_sales_price > 0
),
aggregated AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_catalog_page_number AS catalog_page_number,
        billing.c_birth_year AS birth_year,
        billing.c_birth_month AS birth_month,
        SUM(fs.cs_ext_sales_price) AS total_sales,
        SUM(fs.cs_net_profit) AS total_profit,
        AVG(fs.cs_ext_discount_amt) AS avg_discount,
        SUM(fs.cs_quantity) AS total_quantity
    FROM filtered_sales fs
    JOIN catalog_page cp
        ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer billing
        ON fs.cs_bill_customer_sk = billing.c_customer_sk
    JOIN customer shipping
        ON fs.cs_ship_customer_sk = shipping.c_customer_sk
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_catalog_number IN (1, 2, 3)
    GROUP BY ROLLUP(cp.cp_department, cp.cp_catalog_page_number, billing.c_birth_year, billing.c_birth_month)
    HAVING SUM(fs.cs_ext_sales_price) > 10000
)
SELECT
    department,
    catalog_page_number,
    birth_year,
    birth_month,
    total_sales,
    total_profit,
    avg_discount,
    total_quantity,
    ROUND(total_profit / NULLIF(total_sales, 0), 4) AS profit_margin,
    RANK() OVER (PARTITION BY birth_year ORDER BY total_profit DESC) AS profit_rank_by_year
FROM aggregated
ORDER BY total_profit DESC
LIMIT 100
