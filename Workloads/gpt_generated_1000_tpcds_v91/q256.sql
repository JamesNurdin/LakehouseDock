WITH filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_city,
        cc_state,
        cc_sq_ft,
        cc_street_type
    FROM call_center
    WHERE regexp_like(cc_name, '(?i)center')
      AND cc_sq_ft > 0
      AND cc_street_type LIKE '%Road%'
)
SELECT
    fc.cc_call_center_sk,
    fc.cc_name,
    CONCAT(fc.cc_city, ', ', fc.cc_state) AS location,
    SUBSTR(fc.cc_name, 1, 5) AS name_prefix,
    adr.address_initial,
    COUNT(cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HighVolume'
        ELSE 'LowVolume'
    END AS volume_category,
    CASE
        WHEN fc.cc_sq_ft > 1000000000 THEN 'LargeSpace'
        ELSE 'SmallSpace'
    END AS space_category,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = fc.cc_call_center_sk
    ) AS avg_return_amount_all,
    CASE
        WHEN MAX(CASE WHEN ca.ca_zip LIKE '9%' THEN 1 ELSE 0 END) = 1 THEN 'ZipStarts9'
        ELSE 'OtherZip'
    END AS zip_category
FROM filtered_cc fc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = fc.cc_call_center_sk
JOIN customer_address ca
    ON ca.ca_address_sk = cr.cr_returning_addr_sk
CROSS JOIN LATERAL (
    SELECT regexp_extract(ca.ca_address_id, '^A{7}(.{1})', 1) AS address_initial
) AS adr
GROUP BY
    fc.cc_call_center_sk,
    fc.cc_name,
    fc.cc_city,
    fc.cc_state,
    fc.cc_sq_ft,
    adr.address_initial
ORDER BY total_net_loss DESC
LIMIT 100
