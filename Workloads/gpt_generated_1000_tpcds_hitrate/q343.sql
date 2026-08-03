WITH filtered_sales AS (
  SELECT
    ss.ss_customer_sk,
    ss.ss_cdemo_sk,
    ss.ss_item_sk,
    ss.ss_net_profit,
    ss.ss_ext_list_price,
    ss.ss_ext_sales_price,
    ss.ss_net_paid_inc_tax,
    c.c_customer_id,
    c.c_birth_year,
    c.c_last_review_date,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    cd.cd_dep_college_count
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE ss.ss_net_profit > 100
    AND ss.ss_ext_list_price BETWEEN 1000 AND 4000
    AND c.c_birth_year BETWEEN 1960 AND 1980
    AND cd.cd_purchase_estimate >= 4000
    AND cd.cd_dep_college_count >= 2
    AND c.c_last_review_date > 2452500
),

returns_filtered AS (
  SELECT
    wr.wr_refunded_customer_sk,
    wr.wr_refunded_cdemo_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_net_loss
  FROM web_returns wr
  WHERE wr.wr_return_quantity > 0
    AND wr.wr_return_amt > 0
    AND wr.wr_net_loss IS NOT NULL
),

intersect_customers AS (
  SELECT DISTINCT c.c_customer_id
  FROM customer c
  WHERE c.c_birth_day = 13
  INTERSECT
  SELECT DISTINCT c2.c_customer_id
  FROM customer c2
  JOIN customer_demographics cd2
    ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
  WHERE cd2.cd_gender = 'F'
),

small_dim AS (
  SELECT 1 AS flag UNION ALL SELECT 2 UNION ALL SELECT 3
),

scalar_min_birth_year AS (
  SELECT MIN(c3.c_birth_year) AS min_year
  FROM customer c3
  WHERE c3.c_birth_year > 1900
)

SELECT
  fs.c_customer_id,
  fs.cd_gender,
  COUNT(*) AS sales_count,
  SUM(fs.ss_net_profit) AS total_profit,
  AVG(fs.ss_ext_list_price) AS avg_list_price,
  MIN(fs.ss_net_paid_inc_tax) AS min_paid_inc_tax,
  MAX(fs.ss_net_paid_inc_tax) AS max_paid_inc_tax,
  SUM(rf.wr_net_loss) AS total_return_loss,
  sd.flag
FROM filtered_sales fs
RIGHT OUTER JOIN returns_filtered rf
  ON rf.wr_refunded_customer_sk = fs.ss_customer_sk
JOIN intersect_customers ic
  ON ic.c_customer_id = fs.c_customer_id
CROSS JOIN small_dim sd
WHERE fs.c_birth_year = (SELECT min_year FROM scalar_min_birth_year)
  AND fs.ss_item_sk IN (
    SELECT DISTINCT wr_item_sk
    FROM web_returns
    WHERE wr_return_quantity > 1
  )
GROUP BY
  fs.c_customer_id,
  fs.cd_gender,
  sd.flag
HAVING COUNT(*) > 5
ORDER BY total_profit DESC
LIMIT 100
