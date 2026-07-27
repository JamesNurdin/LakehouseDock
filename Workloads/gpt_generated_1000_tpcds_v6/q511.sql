/*
  Goal: Compare and aggregate net loss from catalog returns and store returns per customer address, flagging addresses with high overall loss. The query uses a UNION ALL to combine two sub‑queries (each with required joins and filters), includes an EXISTS subquery, a scalar subquery for the average catalog net loss, and a CASE expression to categorize overall loss. Results are ordered by total loss descending.
*/
WITH combined AS (
    -- Catalog returns side
    SELECT
        ca.ca_address_id AS address_id,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset BETWEEN -9.00 AND -5.00
    GROUP BY ca.ca_address_id

    UNION ALL

    -- Store returns side
    SELECT
        ca.ca_address_id AS address_id,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND ca.ca_gmt_offset = -8.00
      AND EXISTS (
            SELECT 1
            FROM store s2
            WHERE s2.s_store_sk = sr.sr_store_sk
              AND s2.s_tax_percentage > 0.05
        )
    GROUP BY ca.ca_address_id
)
SELECT
    address_id,
    SUM(total_net_loss) AS overall_net_loss,
    CASE
        WHEN SUM(total_net_loss) > 1500 THEN 'Critical'
        WHEN SUM(total_net_loss) > 800  THEN 'High'
        ELSE 'Normal'
    END AS overall_category,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS avg_catalog_net_loss
FROM combined
GROUP BY address_id
ORDER BY overall_net_loss DESC
LIMIT 100
