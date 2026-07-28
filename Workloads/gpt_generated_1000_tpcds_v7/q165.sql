WITH combined_avg AS (
    SELECT avg(loss) AS avg_loss
    FROM (
        SELECT cr_net_loss AS loss FROM catalog_returns
        UNION ALL
        SELECT sr_net_loss FROM store_returns
    ) t
)
SELECT
    ca.ca_state AS state,
    'Catalog' AS return_type,
    SUM(cr.cr_net_loss) AS total_net_loss,
    (SELECT avg_loss FROM combined_avg) AS avg_net_loss
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
GROUP BY ca.ca_state

UNION ALL

SELECT
    s.s_state AS state,
    'Store' AS return_type,
    SUM(sr.sr_net_loss) AS total_net_loss,
    (SELECT avg_loss FROM combined_avg) AS avg_net_loss
FROM store_returns sr
JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d2.d_year = 2001
GROUP BY s.s_state

ORDER BY total_net_loss DESC
LIMIT 100
