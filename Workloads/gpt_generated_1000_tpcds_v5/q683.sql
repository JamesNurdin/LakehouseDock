SELECT
    d.d_year,
    cd.cd_credit_rating,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_ext_discount_amt > 500
  AND ss.ss_net_paid >= 1000
  AND cd.cd_credit_rating = 'High Risk'
  AND cd.cd_dep_college_count >= 2
  AND d.d_year = 2001
GROUP BY GROUPING SETS (
    (d.d_year, cd.cd_credit_rating),
    (d.d_year),
    (cd.cd_credit_rating),
    ()
)
ORDER BY d.d_year ASC NULLS LAST,
         cd.cd_credit_rating ASC NULLS LAST
