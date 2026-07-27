WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_coupon_amt,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        cs.cs_sold_date_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_coupon_amt > 100
      AND cs.cs_net_paid_inc_ship BETWEEN 500 AND 6000
      AND cs.cs_quantity >= 5
      AND EXISTS (
          SELECT 1
          FROM tpcds.call_center cc2
          WHERE cc2.cc_state = 'CA'
            AND cc2.cc_call_center_sk = cs.cs_call_center_sk
            AND cc2.cc_zip LIKE '75%'
      )
)
SELECT
    cc.cc_company_name,
    cc.cc_division,
    CASE WHEN fs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS quantity_category,
    COUNT(*) AS order_cnt,
    SUM(fs.cs_net_paid_inc_ship) AS total_sales,
    AVG(fs.cs_coupon_amt) AS avg_coupon,
    MIN(fs.cs_net_paid_inc_ship) AS min_sales,
    MAX(fs.cs_net_paid_inc_ship) AS max_sales
FROM filtered_sales fs
JOIN tpcds.call_center cc
    ON fs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_company_name = 'cally'
  AND cc.cc_division = 3
  AND cc.cc_zip = '74593'
GROUP BY
    cc.cc_company_name,
    cc.cc_division,
    CASE WHEN fs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END
ORDER BY total_sales DESC
LIMIT 100
