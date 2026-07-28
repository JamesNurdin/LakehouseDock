WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        cp.cp_end_date_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450800 AND 2451100
      AND cs.cs_quantity > 5
      AND cs.cs_ext_discount_amt > 500
      AND cp.cp_department IN ('Books', 'Electronics', 'Home')
      AND cp.cp_type = 'Online'
      AND cp.cp_end_date_sk >= 2450900
)
SELECT
    f.cs_order_number,
    f.cp_catalog_page_id,
    f.cp_department,
    f.cp_type,
    f.cs_quantity,
    f.cs_ext_sales_price,
    f.cs_ext_discount_amt,
    CASE
        WHEN f.cs_ext_discount_amt / NULLIF(f.cs_ext_sales_price, 0) > 0.20 THEN 'High Discount'
        ELSE 'Standard Discount'
    END AS discount_category,
    f.cs_net_profit,
    RANK() OVER (PARTITION BY f.cp_department ORDER BY f.cs_net_profit DESC) AS profit_rank_by_dept,
    ROW_NUMBER() OVER (ORDER BY f.cs_ext_sales_price DESC) AS overall_sales_rank
FROM filtered_sales f
WHERE EXISTS (
    SELECT 1
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = f.cs_bill_customer_sk
      AND cs2.cs_ext_discount_amt > 1000
      AND cs2.cs_sold_date_sk = f.cs_sold_date_sk
)
ORDER BY profit_rank_by_dept, f.cs_net_profit DESC
LIMIT 100
