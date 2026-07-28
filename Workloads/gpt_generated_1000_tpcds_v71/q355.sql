WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        concat('CC_', cc.cc_call_center_id)            AS call_center_label,
        sm.sm_type                                      AS ship_mode_type,
        regexp_extract(cp.cp_description, '^([^ ]+)', 1) AS description_first_word
    FROM catalog_returns cr
    JOIN catalog_page cp      ON cr.cr_catalog_page_sk   = cp.cp_catalog_page_sk
    JOIN customer_address ca  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN call_center cc       ON cr.cr_call_center_sk   = cc.cc_call_center_sk
    JOIN ship_mode sm         ON cr.cr_ship_mode_sk     = sm.sm_ship_mode_sk
    WHERE regexp_like(cp.cp_description, '\\d{2}')
      AND ca.ca_city LIKE 'A%'
)
SELECT
    call_center_label,
    ship_mode_type,
    description_first_word,
    sum(cr_return_amount) AS total_return_amount,
    sum(cr_return_tax)    AS total_return_tax,
    count(*)              AS return_count
FROM filtered_returns
GROUP BY
    call_center_label,
    ship_mode_type,
    description_first_word
ORDER BY total_return_amount DESC
LIMIT 20
