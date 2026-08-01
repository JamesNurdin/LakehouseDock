WITH item_return_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_container,
        REGEXP_EXTRACT(i.i_item_id, '([A-Z]+)$') AS item_suffix,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_id, '^AAAA')
      AND i.i_container LIKE '%Box%'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, i.i_container
)
SELECT DISTINCT
    ira.i_brand,
    ira.i_item_id,
    ira.item_suffix,
    ira.total_net_loss,
    ira.total_return_qty,
    ira.distinct_tickets,
    ca.ca_city,
    ca.ca_state,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    ROW_NUMBER() OVER (PARTITION BY ira.i_brand ORDER BY ira.total_net_loss DESC) AS brand_rank,
    (SELECT COUNT(*)
     FROM store_returns sr2
     WHERE sr2.sr_item_sk = ira.i_item_sk
       AND sr2.sr_net_loss > ira.total_net_loss) AS higher_loss_item_count
FROM item_return_agg ira
JOIN store_returns sr_outer
    ON sr_outer.sr_item_sk = ira.i_item_sk
JOIN customer_address ca
    ON sr_outer.sr_addr_sk = ca.ca_address_sk
WHERE
    REGEXP_LIKE(ca.ca_street_type, '^(Way|Avenue|Lane)$')
    AND ca.ca_city LIKE 'San%'
    AND ira.total_net_loss > (
        SELECT AVG(sr3.sr_net_loss)
        FROM store_returns sr3
        WHERE sr3.sr_item_sk = ira.i_item_sk
    )
ORDER BY ira.total_net_loss DESC
LIMIT 100
