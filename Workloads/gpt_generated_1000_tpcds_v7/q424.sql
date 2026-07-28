WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_ship_mode_sk,
        cr.cr_returning_addr_sk,
        sm.sm_type,
        sm.sm_ship_mode_id,
        sm.sm_code,
        ca.ca_state,
        ca.ca_zip
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE regexp_like(sm.sm_ship_mode_id, '^AAAAAAA[AB]')
      AND ca.ca_zip LIKE '8%'
)
SELECT
    sm.sm_type AS shipping_mode_type,
    SUBSTR(ca.ca_state, 1, 2) AS state_prefix,
    REGEXP_EXTRACT(sm.sm_ship_mode_id, 'AAAAAAA([AB])', 1) AS mode_variant,
    CONCAT(sm.sm_code, '-', ca.ca_state) AS mode_state_code,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(cs.cs_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax
FROM filtered_returns fr
JOIN catalog_sales cs
    ON fr.cr_order_number = cs.cs_order_number
   AND fr.cr_item_sk = cs.cs_item_sk
JOIN ship_mode sm
    ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
    ON fr.cr_returning_addr_sk = ca.ca_address_sk
GROUP BY
    sm.sm_type,
    SUBSTR(ca.ca_state, 1, 2),
    REGEXP_EXTRACT(sm.sm_ship_mode_id, 'AAAAAAA([AB])', 1),
    CONCAT(sm.sm_code, '-', ca.ca_state)
HAVING SUM(fr.cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
