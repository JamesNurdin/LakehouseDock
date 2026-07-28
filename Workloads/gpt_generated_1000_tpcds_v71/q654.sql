WITH cr AS (
   SELECT
       cr_returned_date_sk,
       cr_ship_mode_sk,
       cr_return_amount,
       cr_fee
   FROM catalog_returns cr
   WHERE cr_return_amount > 0
),
joined AS (
   SELECT
       d.d_year,
       d.d_day_name,
       sm.sm_carrier,
       cr.cr_return_amount,
       cr.cr_fee,
       concat(d.d_day_name, '-', sm.sm_carrier) AS day_carrier,
       regexp_extract(sm.sm_carrier, '([A-Z]+)', 1) AS carrier_prefix,
       CASE WHEN d.d_day_name LIKE 'S%' THEN 'Weekend' ELSE 'Weekday' END AS day_type
   FROM cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_day_name LIKE 'S%'
     AND regexp_like(sm.sm_carrier, '(?i)express')
)
SELECT
    d_year,
    carrier_prefix,
    day_type,
    sum(cr_return_amount) AS total_return_amount,
    sum(cr_fee) AS total_fee,
    count(*) AS return_cnt,
    max(day_carrier) AS example_day_carrier
FROM joined
GROUP BY GROUPING SETS (
    (d_year, carrier_prefix, day_type),
    (d_year, carrier_prefix),
    (d_year),
    ()
)
ORDER BY d_year ASC, carrier_prefix ASC NULLS LAST
LIMIT 100
