WITH store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        CONCAT(s.s_city, ', ', s.s_state) AS store_location,
        REGEXP_EXTRACT(s.s_store_name, '(\\d+)$') AS store_number,
        CASE
            WHEN s.s_store_name LIKE '%Mall%' THEN 'Mall'
            WHEN s.s_store_name LIKE '%Outlet%' THEN 'Outlet'
            ELSE 'Other'
        END AS store_category
    FROM store s
    WHERE
        REGEXP_LIKE(s.s_store_name, '\\d+$')
        AND s.s_city LIKE 'S%'
)
SELECT
    si.store_location,
    si.store_category,
    si.store_number,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_cnt
FROM store_info si
FULL OUTER JOIN store_returns sr
    ON si.s_store_sk = sr.sr_store_sk
GROUP BY
    si.store_location,
    si.store_category,
    si.store_number
HAVING
    COALESCE(SUM(sr.sr_return_amt), 0) > 500
ORDER BY
    total_return_amount DESC,
    si.store_location
OFFSET 0 LIMIT 100
