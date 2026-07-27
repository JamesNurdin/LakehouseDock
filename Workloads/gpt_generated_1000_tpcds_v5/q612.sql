WITH returned_customers AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cr.cr_net_loss) DESC) AS rn_loss_rank
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE cr.cr_net_loss > 0
    AND c.c_salutation = 'Mr.'
  GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
  HAVING COUNT(*) >= 2
),
sales_customers AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(*) AS sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rn_sales_rank
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  WHERE ss.ss_net_paid > 1000
    AND ss.ss_promo_sk IN (
      SELECT promo_sk FROM (VALUES (1145), (194), (938)) AS t(promo_sk)
    )
  GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
  HAVING SUM(ss.ss_net_paid) > 5000
)
SELECT
  rc.c_customer_sk,
  rc.c_first_name,
  rc.c_last_name,
  rc.total_net_loss,
  rc.return_cnt,
  rc.avg_return_amount,
  rc.rn_loss_rank,
  (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_net_loss
FROM returned_customers rc
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss3
  WHERE ss3.ss_customer_sk = rc.c_customer_sk
    AND ss3.ss_net_paid > 2000
)
UNION ALL
SELECT
  sc.c_customer_sk,
  sc.c_first_name,
  sc.c_last_name,
  sc.total_sales AS total_net_loss,
  sc.sales_cnt AS return_cnt,
  CAST(NULL AS decimal(7,2)) AS avg_return_amount,
  sc.rn_sales_rank AS rn_loss_rank,
  (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_net_loss
FROM sales_customers sc
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_returns cr4
  WHERE cr4.cr_refunded_customer_sk = sc.c_customer_sk
)
LIMIT 100
