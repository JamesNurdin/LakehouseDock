SELECT
    cd.cd_gender,
    w.w_city,
    w.w_state,
    COUNT(*) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_tax) AS avg_tax,
    MIN(cs.cs_coupon_amt) AS min_coupon,
    MAX(cs.cs_ext_wholesale_cost) AS max_wholesale_cost
FROM catalog_sales cs
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_employed_count >= 2
  AND cs.cs_ext_wholesale_cost > 1500
  AND cs.cs_ext_tax < 200
  AND cs.cs_coupon_amt BETWEEN 100 AND 2000
  AND w.w_zip = '89275'
GROUP BY cd.cd_gender, w.w_city, w.w_state
ORDER BY total_net_paid DESC
LIMIT 100
