SELECT city_prefix,
       meal_time,
       total_return_amt,
       avg_refunded_cash,
       name_digits,
       rank
FROM (
   SELECT city_prefix,
          meal_time,
          total_return_amt,
          avg_refunded_cash,
          name_digits,
          rank
   FROM (
      SELECT
         SUBSTRING(cc.cc_city, 1, 3) AS city_prefix,
         td.t_meal_time AS meal_time,
         SUM(cr.cr_return_amt_inc_tax) AS total_return_amt,
         AVG(cr.cr_refunded_cash) AS avg_refunded_cash,
         REGEXP_EXTRACT(MIN(cc.cc_name), '([0-9]+)') AS name_digits,
         ROW_NUMBER() OVER (PARTITION BY SUBSTRING(cc.cc_city, 1, 3) ORDER BY SUM(cr.cr_return_amt_inc_tax) DESC) AS rank
      FROM catalog_returns cr
      JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
      WHERE REGEXP_LIKE(cc.cc_name, '[0-9]')
        AND td.t_meal_time LIKE '%unch%'
        AND EXISTS (
            SELECT 1
            FROM household_demographics hd
            WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
              AND hd.hd_dep_count >= 2
        )
      GROUP BY SUBSTRING(cc.cc_city, 1, 3), td.t_meal_time
   ) sub1
   WHERE rank <= 3

   UNION

   SELECT city_prefix,
          meal_time,
          total_return_amt,
          avg_refunded_cash,
          name_digits,
          rank
   FROM (
      SELECT
         SUBSTRING(cc.cc_city, 1, 3) AS city_prefix,
         td.t_meal_time AS meal_time,
         SUM(cr.cr_return_amt_inc_tax) AS total_return_amt,
         AVG(cr.cr_refunded_cash) AS avg_refunded_cash,
         REGEXP_EXTRACT(MIN(cc.cc_name), '([0-9]+)') AS name_digits,
         ROW_NUMBER() OVER (PARTITION BY SUBSTRING(cc.cc_city, 1, 3) ORDER BY SUM(cr.cr_return_amt_inc_tax) DESC) AS rank
      FROM catalog_returns cr
      JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
      WHERE REGEXP_LIKE(cc.cc_name, '^Call Center')
        AND td.t_meal_time LIKE 'dinner%'
        AND cr.cr_return_amt_inc_tax > (
            SELECT AVG(cr2.cr_return_amt_inc_tax)
            FROM catalog_returns cr2
        )
      GROUP BY SUBSTRING(cc.cc_city, 1, 3), td.t_meal_time
   ) sub2
   WHERE rank <= 3
) uq
ORDER BY total_return_amt DESC
LIMIT 100
