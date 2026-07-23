WITH filtered_addresses AS (
    SELECT
        ca_address_sk,
        ca_address_id,
        ca_city,
        ca_state,
        ca_location_type,
        ca_city || '_' || ca_state AS city_state,
        substring(ca_zip, 1, 5) AS zip_prefix,
        regexp_extract(ca_address_id, '\\d+') AS address_id_numeric
    FROM customer_address
    WHERE ca_city LIKE '%Main%'
      OR regexp_like(ca_city, '^[A-Z][a-z]+$')
)
SELECT
    fa.city_state,
    fa.zip_prefix,
    MIN(fa.address_id_numeric) AS sample_address_id_numeric,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(cr.cr_net_loss + sr.sr_net_loss) AS total_net_loss,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_catalog_returns,
    SUM(CASE WHEN sr.sr_return_amt > 100 THEN sr.sr_return_amt ELSE 0 END) AS high_value_store_returns,
    CASE
        WHEN SUM(cr.cr_net_loss + sr.sr_net_loss) > 1000 THEN 'High Loss'
        WHEN SUM(cr.cr_net_loss + sr.sr_net_loss) BETWEEN 100 AND 1000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category
FROM filtered_addresses fa
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_addr_sk = fa.ca_address_sk
LEFT JOIN store_returns sr
    ON sr.sr_addr_sk = fa.ca_address_sk
GROUP BY
    fa.city_state,
    fa.zip_prefix
ORDER BY total_net_loss DESC
LIMIT 100
