WITH date_returns AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_quarter_name,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date, d.d_quarter_name
),
catalog_on_same_date AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_type,
        d.d_date_sk
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_catalog_page_id, '^AAAA.*$')
      AND cp.cp_type LIKE 'quarter%'
)
SELECT
    c.cp_catalog_page_id,
    c.cp_type,
    dr.d_quarter_name,
    dr.return_cnt,
    dr.total_net_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
    MAX(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)) AS example_domain
FROM catalog_on_same_date c
JOIN date_returns dr ON c.d_date_sk = dr.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_access_date_sk = dr.d_date_sk
    AND regexp_like(wp.wp_url, '^https?://.*example\\.com')
WHERE EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_customer_sk = 11750971
      AND sr2.sr_returned_date_sk = dr.d_date_sk
)
GROUP BY
    c.cp_catalog_page_id,
    c.cp_type,
    dr.d_quarter_name,
    dr.return_cnt,
    dr.total_net_loss
HAVING dr.total_net_loss > 200
ORDER BY dr.total_net_loss DESC
LIMIT 100
