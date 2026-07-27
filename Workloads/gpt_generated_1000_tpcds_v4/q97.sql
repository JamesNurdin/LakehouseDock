WITH recent_sales AS (
    SELECT c.c_customer_sk,
           c.c_current_cdemo_sk,
           c.c_current_hdemo_sk,
           c.c_first_sales_date_sk
    FROM tpcds.customer c
    JOIN tpcds.date_dim d_sales
      ON c.c_first_sales_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_fy_year = 1908
)
SELECT
    d_ship.d_year AS ship_year,
    hd.hd_buy_potential,
    cd.cd_gender,
    COUNT(DISTINCT r.c_customer_sk) AS customer_cnt,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(c.c_birth_year) AS min_birth_year,
    MAX(c.c_birth_year) AS max_birth_year
FROM recent_sales r
JOIN tpcds.customer c
  ON r.c_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.date_dim d_ship
  ON c.c_first_shipto_date_sk = d_ship.d_date_sk
WHERE c.c_birth_country IN ('KOREA', 'UKRAINE')
  AND hd.hd_buy_potential = '1001-5000'
  AND hd.hd_dep_count >= 3
  AND d_ship.d_fy_week_seq BETWEEN 5 AND 20
  AND EXISTS (
        SELECT 1
        FROM tpcds.date_dim d_check
        WHERE d_check.d_date_sk = c.c_first_shipto_date_sk
          AND d_check.d_fy_year = 1905
      )
GROUP BY d_ship.d_year, hd.hd_buy_potential, cd.cd_gender
HAVING COUNT(DISTINCT r.c_customer_sk) > (
        SELECT AVG(cnt) FROM (
            SELECT COUNT(*) AS cnt
            FROM tpcds.customer
            GROUP BY c_current_cdemo_sk
        ) sub
    )
ORDER BY customer_cnt DESC
LIMIT 100
