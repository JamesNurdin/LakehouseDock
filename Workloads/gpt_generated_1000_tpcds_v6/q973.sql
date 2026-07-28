WITH base AS (
   SELECT
       ib.ib_income_band_sk,
       d.d_moy AS month,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       COUNT(DISTINCT c.c_customer_sk) AS cust_cnt
   FROM customer c
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
   JOIN inventory i ON i.inv_date_sk = d.d_date_sk
   WHERE c.c_birth_year BETWEEN 1970 AND 1990
     AND c.c_preferred_cust_flag = 'Y'
     AND hd.hd_vehicle_count >= 1
     AND ib.ib_lower_bound >= 20000
     AND d.d_moy IN (2, 6, 12)
     AND i.inv_quantity_on_hand > 0
   GROUP BY GROUPING SETS (
       (ib.ib_income_band_sk, d.d_moy),
       (ib.ib_income_band_sk),
       (d.d_moy),
       ()
   )
)
SELECT
    ib_income_band_sk,
    month,
    total_qty,
    cust_cnt,
    total_qty / NULLIF(cust_cnt, 0) AS avg_qty_per_cust,
    (SELECT AVG(total_qty) FROM base) AS overall_avg_qty
FROM base
WHERE total_qty > (SELECT AVG(total_qty) FROM base)
  AND total_qty / NULLIF(cust_cnt, 0) > 5
ORDER BY ib_income_band_sk ASC, month ASC NULLS LAST, total_qty DESC
LIMIT 100
