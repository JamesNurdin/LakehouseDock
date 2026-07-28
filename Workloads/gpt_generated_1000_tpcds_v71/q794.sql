WITH filtered_calls AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_sq_ft,
        cc_state,
        cc_gmt_offset,
        cc_employees
    FROM call_center
    WHERE cc_sq_ft > 1000000
      AND cc_state = 'CA'
      AND cc_mkt_desc LIKE '%realistic%'
      AND cc_employees BETWEEN 100 AND 2000
      AND cc_gmt_offset BETWEEN -5 AND 5
),
filtered_ship AS (
    SELECT
        sm_ship_mode_sk,
        sm_carrier,
        sm_type,
        sm_code,
        sm_contract
    FROM ship_mode
    WHERE sm_carrier IN ('USPS', 'DHL')
      AND sm_type = 'AIR'
      AND sm_code = 'AIR'
      AND sm_contract LIKE 'G%'
),
union_source AS (
    SELECT
        cc_call_center_sk AS key_id,
        cc_name AS description,
        'call_center' AS source_type
    FROM filtered_calls
    UNION ALL
    SELECT
        sm_ship_mode_sk AS key_id,
        sm_carrier AS description,
        'ship_mode' AS source_type
    FROM filtered_ship
)
SELECT
    cr.cr_order_number,
    fc.cc_name,
    sm.sm_carrier,
    cr.cr_return_amount,
    CASE
        WHEN cr.cr_return_amount > 5000 THEN 'High'
        WHEN cr.cr_return_amount > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY fc.cc_call_center_sk ORDER BY cr.cr_return_amount DESC) AS rn_return_amount,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_call_center_sk = cr.cr_call_center_sk) AS total_returns_for_center,
    (SELECT COUNT(*) FROM union_source) AS union_row_count
FROM catalog_returns cr
JOIN filtered_calls fc
    ON cr.cr_call_center_sk = fc.cc_call_center_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_return_amount > 0
  AND cr.cr_return_ship_cost > 50
  AND cr.cr_return_quantity >= 1
  AND sm.sm_carrier = 'USPS'
  AND EXISTS (
        SELECT 1
        FROM filtered_ship fs
        WHERE fs.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND fs.sm_carrier = 'USPS'
    )
ORDER BY cr.cr_return_amount DESC, rn_return_amount
LIMIT 100
