WITH returns_filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_refunded_addr_sk,
        cr.cr_item_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND regexp_like(CAST(cr.cr_return_amount AS varchar), '^1[0-9]{2}\\.')
), avg_return_2020 AS (
    SELECT AVG(cr_return_amount) AS avg_amt
    FROM catalog_returns cr2
    WHERE cr2.cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2020
    )
)
SELECT
    s.s_store_id,
    s.s_store_name,
    substring(s.s_store_name, 1, 10) AS short_name,
    d.d_year,
    SUM(rf.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CONCAT('Store_', s.s_store_id) AS store_key,
    regexp_extract(MIN(ca.ca_city), '(.*)') AS city_name
FROM returns_filtered rf
JOIN date_dim d ON rf.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON rf.cr_refunded_addr_sk = ca.ca_address_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2020
  AND ca.ca_city LIKE '%York%'
  AND regexp_like(ca.ca_city, 'York')
  AND s.s_suite_number LIKE 'Suite 2%'
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = rf.cr_item_sk
          AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY s.s_store_id, s.s_store_name, substring(s.s_store_name, 1, 10), d.d_year
HAVING SUM(rf.cr_return_amount) > (SELECT avg_amt * 1.5 FROM avg_return_2020)
ORDER BY total_return_amount DESC
LIMIT 100
