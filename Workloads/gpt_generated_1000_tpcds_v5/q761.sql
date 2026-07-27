WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ext_ship_cost,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_sales_price
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 500
      AND cs.cs_quantity >= 2
      AND EXISTS (
          SELECT 1
          FROM tpcds.customer_demographics cd
          WHERE cd.cd_demo_sk = cs.cs_bill_cdemo_sk
            AND cd.cd_education_status = 'Advanced Degree'
      )
)
SELECT
    cc.cc_call_center_id,
    cc.cc_company_name,
    cd.cd_gender,
    cd.cd_education_status,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_net_profit) AS avg_profit,
    COUNT(*) AS sales_cnt,
    MIN(fs.cs_ext_ship_cost) AS min_ship_cost,
    MAX(fs.cs_ext_ship_cost) AS max_ship_cost
FROM filtered_sales fs
JOIN tpcds.call_center cc
    ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.customer_demographics cd
    ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_rec_end_date = DATE '2000-12-31'
  AND cc.cc_country = 'United States'
  AND cd.cd_dep_college_count >= 3
GROUP BY
    cc.cc_call_center_id,
    cc.cc_company_name,
    cd.cd_gender,
    cd.cd_education_status
ORDER BY total_sales DESC
LIMIT 100
