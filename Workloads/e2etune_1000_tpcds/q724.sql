WITH catalog_agg AS (
    SELECT
        ca.ca_state AS state,
        ca.ca_city AS city,
        SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return_amount,
        COUNT(*) AS catalog_return_count,
        AVG(cr.cr_net_loss) AS avg_catalog_net_loss
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amt_inc_tax > 500
      AND cr.cr_refunded_addr_sk IN (1501488, 3887022, 715671, 1727086, 3158770)
    GROUP BY ca.ca_state, ca.ca_city
),
store_agg AS (
    SELECT
        ca.ca_state AS state,
        ca.ca_city AS city,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
        COUNT(*) AS store_return_count,
        AVG(sr.sr_net_loss) AS avg_store_net_loss
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt_inc_tax > 500
      AND sr.sr_addr_sk IN (1501488, 3887022, 715671, 1727086, 3158770)
    GROUP BY ca.ca_state, ca.ca_city
)
SELECT
    COALESCE(ca.state, sa.state) AS state,
    COALESCE(ca.city, sa.city) AS city,
    COALESCE(ca.total_catalog_return_amount, 0) AS total_catalog_return_amount,
    COALESCE(sa.total_store_return_amount, 0) AS total_store_return_amount,
    COALESCE(ca.catalog_return_count, 0) + COALESCE(sa.store_return_count, 0) AS total_return_count,
    (COALESCE(ca.avg_catalog_net_loss, 0) * COALESCE(ca.catalog_return_count, 0) + COALESCE(sa.avg_store_net_loss, 0) * COALESCE(sa.store_return_count, 0))
        / NULLIF(COALESCE(ca.catalog_return_count, 0) + COALESCE(sa.store_return_count, 0), 0) AS avg_net_loss,
    (COALESCE(ca.total_catalog_return_amount, 0) + COALESCE(sa.total_store_return_amount, 0)) AS total_return_amount,
    RANK() OVER (PARTITION BY COALESCE(ca.state, sa.state) ORDER BY (COALESCE(ca.total_catalog_return_amount, 0) + COALESCE(sa.total_store_return_amount, 0)) DESC) AS city_rank
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
    ON ca.state = sa.state
   AND ca.city = sa.city
WHERE (COALESCE(ca.total_catalog_return_amount, 0) + COALESCE(sa.total_store_return_amount, 0)) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
