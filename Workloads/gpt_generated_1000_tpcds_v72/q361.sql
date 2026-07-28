WITH filtered_returns AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_refunded_cdemo_sk,
    cr.cr_warehouse_sk,
    cr.cr_return_amount,
    cr.cr_refunded_customer_sk
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2021
    AND REGEXP_LIKE(w.w_street_name, '.*[0-9].*')
    AND w.w_city LIKE 'A%'
)

SELECT
  cd.cd_gender,
  w.w_state,
  CONCAT(cd.cd_gender, '-', w.w_state) AS gender_state_key,
  SUM(fr.cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT fr.cr_refunded_customer_sk) AS distinct_refunded_customers,
  (SELECT COUNT(*) FROM store s WHERE s.s_state = w.w_state) AS store_count_in_state,
  (SELECT COUNT(DISTINCT w2.w_street_name) FROM warehouse w2 WHERE w2.w_state = w.w_state) AS distinct_warehouse_streets_in_state
FROM filtered_returns fr
JOIN customer_demographics cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2021
      AND ss.ss_cdemo_sk = cd.cd_demo_sk
)
GROUP BY cd.cd_gender, w.w_state
ORDER BY total_return_amount DESC
LIMIT 100
