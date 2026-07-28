WITH filtered AS (
    SELECT
        s.s_store_name               AS store_name,
        ca.ca_location_type          AS ca_location_type,
        ca.ca_address_id             AS ca_address_id,
        regexp_extract(ca.ca_address_id, '(....)(.*)', 2) AS addr_suffix,
        sr.sr_net_loss               AS sr_net_loss,
        r.r_reason_desc              AS r_reason_desc
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price')
      AND ca.ca_address_id LIKE 'AAAA%'
)
SELECT
    store_name,
    ca_location_type,
    addr_suffix,
    COUNT(*)                     AS return_cnt,
    SUM(sr_net_loss)             AS total_loss
FROM filtered
GROUP BY
    store_name,
    ca_location_type,
    addr_suffix
ORDER BY total_loss DESC
LIMIT 100
