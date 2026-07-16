SELECT
    cp.cp_department,
    cd.cd_gender,
    cd.cd_education_status,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_coupon_amt) AS avg_coupon_amount,
    SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp
  ON ss.ss_sold_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
WHERE cp.cp_department = 'DEPARTMENT'
  AND cp.cp_catalog_page_number IN (1, 2, 3)
  AND cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
  AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
GROUP BY cp.cp_department, cd.cd_gender, cd.cd_education_status
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 10
