WITH ca_sample AS (
    SELECT *
    FROM customer_address
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    s_store.s_store_name,
    r_sr.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    COUNT(DISTINCT ca_refunded.ca_state) AS distinct_refunded_states,
    COUNT(DISTINCT ca_returning.ca_city) AS distinct_returning_cities,
    CASE WHEN SUM(sr.sr_return_quantity) > 100 THEN 'HIGH_VOLUME' ELSE 'LOW_VOLUME' END AS volume_category
FROM store_returns sr
JOIN ca_sample ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk                                 -- join 1
JOIN store s_store
    ON sr.sr_store_sk = s_store.s_store_sk                                 -- join 2
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk                                 -- join 3
JOIN catalog_returns cr
    ON cr.cr_reason_sk = r_sr.r_reason_sk                                 -- join 4 (catalog to same reason as store)
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk                                 -- join 5 (second reason alias for catalog)
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk                 -- join 6
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk               -- join 7
JOIN store s_store2
    ON sr.sr_store_sk = s_store2.s_store_sk                               -- join 8 (store used a second time)
JOIN reason r_sr2
    ON sr.sr_reason_sk = r_sr2.r_reason_sk                               -- join 9 (reason used a second time)
WHERE sr.sr_store_credit > (SELECT MAX(cr_fee) FROM catalog_returns)   -- scalar subquery
  AND r_sr.r_reason_id IN (
        SELECT r_reason_id FROM reason WHERE r_reason_desc LIKE '%damaged%'
    )
  AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = r_sr.r_reason_sk
          AND cr2.cr_refunded_addr_sk = ca_sr.ca_address_sk
    )
GROUP BY s_store.s_store_name, r_sr.r_reason_desc
ORDER BY total_store_return_loss DESC
LIMIT 100
