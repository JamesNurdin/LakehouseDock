WITH filtered_returns AS (
   SELECT
     cr.cr_returned_date_sk,
     cr.cr_returned_time_sk,
     cr.cr_return_amount,
     cr.cr_return_tax,
     cr.cr_return_amt_inc_tax,
     cr.cr_ship_mode_sk,
     sm.sm_carrier,
     sm.sm_code,
     sm.sm_ship_mode_id,
     td.t_meal_time,
     td.t_time,
     concat(sm.sm_carrier, '-', sm.sm_code) AS carrier_mode,
     CASE
       WHEN cr.cr_return_amount > 1000 THEN 'HIGH'
       WHEN cr.cr_return_amount > 500 THEN 'MEDIUM'
       ELSE 'LOW'
     END AS amount_category,
     regexp_extract(sm.sm_ship_mode_id, '(A{5,})', 1) AS extracted_pattern
   FROM catalog_returns cr
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE regexp_like(sm.sm_carrier, '^D.*')                -- carriers starting with D
     AND sm.sm_code LIKE 'A%'                           -- ship mode code starts with A
     AND substring(td.t_time_id, 1, 3) = 'AAA'          -- first three chars of time id are AAA
)

SELECT carrier_mode,
       amount_category,
       total_inc_tax,
       cnt,
       running_total
FROM (
   SELECT carrier_mode,
          amount_category,
          total_inc_tax,
          cnt,
          sum(total_inc_tax) OVER (PARTITION BY carrier_mode ORDER BY amount_category) AS running_total
   FROM (
      SELECT carrier_mode,
             amount_category,
             sum(cr_return_amt_inc_tax) AS total_inc_tax,
             count(*) AS cnt
      FROM filtered_returns
      GROUP BY carrier_mode, amount_category
   ) agg1
) a

UNION ALL

SELECT carrier_mode,
       amount_category,
       total_inc_tax,
       cnt,
       running_total
FROM (
   SELECT carrier_mode,
          amount_category,
          total_inc_tax,
          cnt,
          sum(total_inc_tax) OVER (PARTITION BY carrier_mode ORDER BY amount_category DESC) AS running_total
   FROM (
      SELECT carrier_mode,
             amount_category,
             sum(cr_return_amt_inc_tax) AS total_inc_tax,
             count(*) AS cnt
      FROM filtered_returns
      WHERE t_meal_time = 'dinner'
      GROUP BY carrier_mode, amount_category
   ) agg2
) b

ORDER BY carrier_mode, amount_category
