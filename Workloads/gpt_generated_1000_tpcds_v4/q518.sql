WITH filtered AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        cr.cr_return_amount,
        i.i_item_sk,
        i.i_manufact_id,
        i.i_manufact,
        i.i_item_desc,
        ca.ca_state,
        ca.ca_street_number,
        ca.ca_street_name,
        concat(ca.ca_street_number, ' ', ca.ca_street_name) AS full_street
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_street_name, '^S')
      AND ca.ca_state = 'CA'
)
SELECT
    f.i_manufact,
    f.i_manufact_id,
    SUM(f.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT f.cr_order_number) AS distinct_orders,
    AVG(f.cr_return_amount) AS avg_return_amount,
    regexp_extract(f.i_item_desc, '(\\d+)', 1) AS extracted_number,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = f.i_item_sk) AS overall_avg_return_amount
FROM filtered f
WHERE regexp_like(f.i_item_desc, '\\d+')
  AND (f.full_street LIKE '%Ave%' OR f.full_street LIKE '%Street%')
  AND f.i_manufact IN (
        SELECT DISTINCT i2.i_manufact
        FROM item i2
        WHERE i2.i_units = 'Carton'
    )
GROUP BY
    f.i_manufact,
    f.i_manufact_id,
    f.i_item_desc,
    f.i_item_sk
HAVING SUM(f.cr_net_loss) > 1000
ORDER BY total_net_loss DESC, f.i_manufact
LIMIT 100
