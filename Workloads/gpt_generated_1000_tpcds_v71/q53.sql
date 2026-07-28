WITH filtered_returns AS (
   SELECT cr.*
   FROM catalog_returns cr
   WHERE cr.cr_return_amount > 100
     AND cr.cr_return_quantity >= 2
     AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
     AND cr.cr_reversed_charge < 500
     AND cr.cr_fee IS NOT NULL
     AND cr.cr_returning_hdemo_sk IS NOT NULL
),
joined_hd AS (
   SELECT fr.*, hd.hd_dep_count, hd.hd_vehicle_count,
          hd.hd_buy_potential, hd.hd_income_band_sk
   FROM filtered_returns fr
   JOIN household_demographics hd
     ON fr.cr_returning_hdemo_sk = hd.hd_demo_sk
),
joined_reason AS (
   SELECT jh.*, r.r_reason_id, r.r_reason_desc
   FROM joined_hd jh
   JOIN reason r
     ON jh.cr_reason_sk = r.r_reason_sk
   WHERE jh.hd_dep_count IN (2, 3, 4, 7, 9)
     AND jh.hd_vehicle_count >= 1
     AND r.r_reason_id LIKE 'AAAAAAA%'
)
SELECT
   jr.cr_order_number,
   jr.cr_return_amount,
   jr.cr_return_quantity,
   jr.hd_buy_potential,
   jr.hd_income_band_sk,
   jr.r_reason_desc,
   RANK() OVER (PARTITION BY jr.hd_buy_potential ORDER BY jr.cr_return_amount DESC) AS amt_rank
FROM joined_reason jr
WHERE NOT EXISTS (
   SELECT 1
   FROM catalog_returns cr2
   WHERE cr2.cr_returning_customer_sk = jr.cr_returning_customer_sk
     AND cr2.cr_reversed_charge > 1000
)
ORDER BY amt_rank ASC, jr.cr_return_amount DESC
LIMIT 100
