WITH avg_return AS (
   SELECT avg(cr_return_amount) AS avg_amt
   FROM catalog_returns
)
SELECT
   cc.cc_name AS call_center_name,
   CONCAT(cc.cc_city, ', ', cc.cc_state) AS city_state,
   sm.sm_code AS ship_mode_code,
   SUBSTRING(cc.cc_zip, 1, 3) AS zip_prefix,
   COUNT(cr.cr_order_number) AS returns_count,
   SUM(cr.cr_return_amount) AS total_return_amount,
   AVG(cr.cr_return_amount) AS avg_return_amount,
   regexp_extract(MIN(cp.cp_description), '(\\w+)', 1) AS first_word_desc
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
WHERE
   regexp_like(cp.cp_description, '(?i)care|legal')
   AND cc.cc_city LIKE 'S%'
   AND SUBSTRING(cc.cc_zip, 1, 3) IN ('100', '200', '303')
   AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = cr.cr_ship_mode_sk
          AND cr2.cr_return_quantity > 5
   )
GROUP BY
   cc.cc_name,
   cc.cc_city,
   cc.cc_state,
   sm.sm_code,
   cc.cc_zip
HAVING
   SUM(cr.cr_return_amount) > (SELECT avg_amt FROM avg_return)
ORDER BY
   total_return_amount DESC,
   returns_count DESC
LIMIT 100
