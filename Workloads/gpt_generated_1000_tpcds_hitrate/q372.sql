/* goal: calculate total net paid and related metrics across catalog and store sales, broken down by department, brand, gender and hour, applying selective filters and a scalar subquery */
WITH filtered_sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_wholesale_cost
    FROM catalog_sales cs
    WHERE cs.cs_wholesale_cost > 30
      AND cs.cs_ext_discount_amt > (
          SELECT AVG(cs2.cs_ext_discount_amt)
          FROM catalog_sales cs2
          WHERE cs2.cs_wholesale_cost > 30
      )
),
distinct_pages AS (
    SELECT DISTINCT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cp.cp_catalog_page_id
    FROM catalog_page cp
    WHERE cp.cp_catalog_page_number IN (11, 13)
)
SELECT
    cp.cp_department,
    i.i_brand,
    cd.cd_gender,
    td.t_hour,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    MIN(fs.cs_wholesale_cost) AS min_wholesale,
    MAX(fs.cs_wholesale_cost) AS max_wholesale
FROM filtered_sales fs
JOIN distinct_pages cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON fs.cs_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN time_dim td
    ON fs.cs_sold_time_sk = td.t_time_sk
JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
   AND ss.ss_item_sk = i.i_item_sk
   AND ss.ss_cdemo_sk = cd.cd_demo_sk
GROUP BY CUBE (cp.cp_department, i.i_brand, cd.cd_gender, td.t_hour)
ORDER BY total_net_paid DESC
LIMIT 100
