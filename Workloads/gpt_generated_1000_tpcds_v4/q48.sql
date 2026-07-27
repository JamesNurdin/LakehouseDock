/* goal: Summarize return amounts by carrier/type combinations for carriers matching specific patterns, using regex and string functions, and compare against average metrics via subqueries */
WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reversed_charge,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_ship_cost,
        sm.sm_carrier,
        sm.sm_type,
        sm.sm_code,
        CONCAT(sm.sm_carrier, '-', sm.sm_type) AS carrier_type_concat,
        SUBSTRING(sm.sm_carrier, 1, 3) AS carrier_prefix,
        regexp_extract(sm.sm_carrier, '(AIR|ALLIANCE|TBS|ORIENTAL|MSC)', 1) AS carrier_match
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(sm.sm_carrier, '^(AIR|ALLIANCE|MSC)$')
      AND sm.sm_type LIKE 'OVER%'
)
SELECT
    carrier_type_concat,
    carrier_prefix,
    carrier_match,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_quantity,
    SUM(cr_return_ship_cost) AS total_ship_cost,
    (SELECT AVG(cr2.cr_reversed_charge)
     FROM catalog_returns cr2
     WHERE cr2.cr_reason_sk = 27) AS avg_rev_charge_reason27
FROM filtered_returns
GROUP BY carrier_type_concat, carrier_prefix, carrier_match
HAVING SUM(cr_return_amount) > (
    SELECT AVG(cr_return_amount)
    FROM catalog_returns
    WHERE cr_reason_sk = 15
)
ORDER BY total_return_amount DESC
LIMIT 100
