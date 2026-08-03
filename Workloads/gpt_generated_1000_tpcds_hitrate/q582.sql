WITH years AS (
       SELECT DISTINCT d_year
       FROM date_dim
       WHERE d_year BETWEEN 2000 AND 2002
     ),
     reason_filtered AS (
       SELECT r_reason_sk
       FROM reason
       WHERE r_reason_desc LIKE '%damage%'
     ),
     catalog_agg AS (
       SELECT 
         d.d_year AS period_year,
         CASE WHEN cs.cs_ext_tax > 50 THEN 'HIGH' ELSE 'LOW' END AS tax_level,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         COUNT(*) AS sales_cnt
       FROM catalog_sales cs
       JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
       JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
       WHERE cd.cd_gender = 'M'
         AND d.d_year = 2001
         AND cs.cs_ext_discount_amt > (
           SELECT AVG(cs2.cs_ext_discount_amt)
           FROM catalog_sales cs2
           WHERE cs2.cs_sold_date_sk IN (
             SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2000
           )
         )
       GROUP BY d.d_year,
                CASE WHEN cs.cs_ext_tax > 50 THEN 'HIGH' ELSE 'LOW' END
     ),
     store_agg AS (
       SELECT 
         d.d_year AS period_year,
         CASE WHEN sr.sr_return_amt > 100 THEN 'BIG' ELSE 'SMALL' END AS return_size,
         SUM(sr.sr_net_loss) AS total_loss,
         COUNT(*) AS return_cnt
       FROM store_returns sr
       JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
       JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
       WHERE cd.cd_gender = 'F'
         AND d.d_year = 2001
         AND sr.sr_reason_sk IN (SELECT r_reason_sk FROM reason_filtered)
         AND sr.sr_return_amt > (
           SELECT AVG(sr2.sr_return_amt)
           FROM store_returns sr2
           WHERE sr2.sr_returned_date_sk IN (
             SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2000
           )
         )
       GROUP BY d.d_year,
                CASE WHEN sr.sr_return_amt > 100 THEN 'BIG' ELSE 'SMALL' END
     ),
     combined AS (
       SELECT period_year,
              tax_level AS category,
              total_sales AS amount,
              sales_cnt AS cnt
       FROM catalog_agg
       UNION ALL
       SELECT period_year,
              return_size AS category,
              total_loss AS amount,
              return_cnt AS cnt
       FROM store_agg
     )
SELECT 
  c.period_year,
  c.category,
  c.amount,
  c.cnt,
  ROW_NUMBER() OVER (PARTITION BY c.period_year ORDER BY c.amount DESC) AS rank_within_year
FROM combined c
CROSS JOIN (SELECT d_year FROM years) y
WHERE c.period_year = y.d_year
ORDER BY c.period_year, rank_within_year
