WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 100
      AND cs.cs_quantity >= 1
    GROUP BY cs.cs_order_number, cs.cs_catalog_page_sk, cs.cs_bill_cdemo_sk, cs.cs_sold_time_sk
),
returns_agg AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_dates,
        SUM(cr.cr_store_credit) AS total_store_credit,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_store_credit > 0
    GROUP BY cr.cr_order_number
)
SELECT
    cp.cp_department,
    td.t_meal_time,
    cd.cd_gender,
    cd.cd_marital_status,
    sa.total_sales,
    sa.total_quantity,
    sa.distinct_items_sold,
    ra.total_return_amount,
    ra.distinct_return_dates,
    CASE WHEN ra.total_store_credit > 30 THEN 'High' ELSE 'Low' END AS credit_category,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS dept_sales_rank
FROM sales_agg sa
JOIN catalog_page cp
    ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
    ON sa.cs_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd
    ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns_agg ra
    ON sa.cs_order_number = ra.cr_order_number
WHERE cp.cp_department = 'Electronics'
  AND td.t_meal_time IN ('breakfast', 'lunch')
  AND td.t_hour BETWEEN 9 AND 17
  AND cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND ra.total_store_credit IS NOT NULL
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_order_number = sa.cs_order_number
          AND cr_sub.cr_return_amount > 50
    )
ORDER BY dept_sales_rank, cp.cp_catalog_page_number
LIMIT 100
