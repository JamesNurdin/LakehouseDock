WITH sales_by_group AS (
    SELECT
        cp.cp_department,
        i.i_class_id,
        td.t_meal_time,
        hd.hd_buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_qty,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_class_id IN (4, 14, 5)
      AND i.i_units = 'Box'
      AND hd.hd_vehicle_count >= 2
      AND cp.cp_department = 'Electronics'
      AND td.t_meal_time = 'dinner'
      AND cs.cs_quantity > 2
      AND i.i_item_sk IN (
          SELECT cs2.cs_item_sk
          FROM catalog_sales cs2
          GROUP BY cs2.cs_item_sk
          HAVING SUM(cs2.cs_ext_sales_price) > 5000
      )
    GROUP BY GROUPING SETS (
        (cp.cp_department, i.i_class_id, td.t_meal_time, hd.hd_buy_potential),
        (cp.cp_department, i.i_class_id, td.t_meal_time),
        (cp.cp_department, i.i_class_id),
        (cp.cp_department),
        ()
    )
)
SELECT
    department,
    SUM(total_sales) AS dept_sales,
    SUM(total_qty) AS dept_qty,
    SUM(txn_cnt) AS dept_txn,
    AVG(total_sales / NULLIF(total_qty, 0)) AS avg_price_per_txn
FROM (
    SELECT
        cp_department AS department,
        total_sales,
        total_qty,
        txn_cnt
    FROM sales_by_group
) agg
WHERE total_sales > 10000
GROUP BY department
HAVING AVG(total_sales / NULLIF(total_qty, 0)) > 20
ORDER BY dept_sales DESC
LIMIT 100
