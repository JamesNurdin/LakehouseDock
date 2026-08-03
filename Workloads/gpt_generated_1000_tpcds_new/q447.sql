WITH filtered_pages AS (
    SELECT cp_catalog_page_sk,
           cp_department,
           cp_type,
           cp_catalog_page_number
    FROM catalog_page
    WHERE cp_department = 'Books'
      AND cp_type = 'Promotion'
      AND cp_catalog_page_number = 2
),
excluded_pages AS (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_catalog_number = 5
    EXCEPT
    SELECT cs_catalog_page_sk
    FROM catalog_sales
    WHERE cs_quantity > 0
),
joined_data AS (
    SELECT cp.cp_catalog_page_sk,
           cp.cp_department,
           cp.cp_type,
           cs.cs_order_number,
           cs.cs_ext_sales_price,
           cs.cs_ext_discount_amt,
           cs.cs_net_paid_inc_ship_tax,
           cs.cs_quantity,
           cs.cs_wholesale_cost,
           hd.hd_demo_sk,
           hd.hd_income_band_sk,
           hd.hd_dep_count,
           ss.ss_item_sk,
           ss.ss_ext_tax,
           ss.ss_wholesale_cost,
           ARRAY[cs.cs_quantity, cs.cs_wholesale_cost] AS qty_cost_arr
    FROM filtered_pages cp
    JOIN catalog_sales cs
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
      ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN store_sales ss
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_discount_amt > 1000
      AND cs.cs_net_paid_inc_ship_tax < 5000
      AND hd.hd_income_band_sk IN (1, 2, 3)
      AND ss.ss_ext_tax BETWEEN 10 AND 300
      AND ss.ss_wholesale_cost > 20
),
final_result AS (
    SELECT jd.cp_department,
           jd.cp_type,
           CASE WHEN jd.cs_ext_discount_amt > 2000 THEN 'High' ELSE 'Low' END AS discount_category,
           SUM(jd.cs_ext_sales_price) AS total_sales,
           AVG(jd.ss_ext_tax) AS avg_tax,
           COUNT(DISTINCT jd.cs_order_number) AS order_cnt,
           MIN(jd.cs_ext_discount_amt) AS min_discount,
           MAX(jd.cs_ext_discount_amt) AS max_discount,
           (
               SELECT SUM(ss2.ss_ext_sales_price)
               FROM store_sales ss2
               WHERE ss2.ss_hdemo_sk = jd.hd_demo_sk
                 AND ss2.ss_item_sk = jd.ss_item_sk
           ) AS related_store_sales,
           qty_val AS qty_or_cost,
           ep.cp_catalog_page_sk AS excluded_page_sk
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.qty_cost_arr) AS t(qty_val)
    LEFT JOIN excluded_pages ep
      ON ep.cp_catalog_page_sk = jd.cp_catalog_page_sk
    GROUP BY jd.cp_department,
             jd.cp_type,
             CASE WHEN jd.cs_ext_discount_amt > 2000 THEN 'High' ELSE 'Low' END,
             jd.hd_demo_sk,
             jd.ss_item_sk,
             qty_val,
             ep.cp_catalog_page_sk
    HAVING SUM(jd.cs_ext_sales_price) > 5000
)
SELECT *
FROM final_result
ORDER BY total_sales DESC
LIMIT 100
