WITH filtered_warehouse AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city,
        w_county,
        w_street_number,
        w_street_name,
        regexp_extract(w_street_number, '\\d+') AS street_number_digits,
        concat(w_street_number, ' ', w_street_name, ', ', w_city) AS full_address
    FROM warehouse
    WHERE regexp_like(w_street_name, '[A-Za-z]')
      AND w_street_name LIKE '%e%'
)
SELECT
    fw.w_county,
    fw.w_city,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY fw.w_county ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
FROM filtered_warehouse fw
JOIN catalog_returns cr
     ON cr.cr_warehouse_sk = fw.w_warehouse_sk
WHERE cr.cr_return_amount > 100
  AND cr.cr_reason_sk IN (20, 24, 29)
GROUP BY fw.w_county, fw.w_city
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 10
