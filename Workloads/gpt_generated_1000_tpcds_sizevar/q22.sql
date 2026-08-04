WITH catalog_top AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id AS customer_id,
        cr.cr_net_loss AS net_loss,
        'catalog' AS source,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_net_loss DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
),
catalog_ranked AS (
    SELECT year, customer_id, net_loss, source
    FROM catalog_top
    WHERE rn <= 5
),
web_top AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id AS customer_id,
        wr.wr_net_loss AS net_loss,
        'web' AS source,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY wr.wr_net_loss DESC) AS rn
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
),
web_ranked AS (
    SELECT year, customer_id, net_loss, source
    FROM web_top
    WHERE rn <= 5
),
union_all AS (
    SELECT year, customer_id, net_loss, source FROM catalog_ranked
    UNION
    SELECT year, customer_id, net_loss, source FROM web_ranked
),
small_reasons AS (
    SELECT r_reason_id
    FROM reason
    WHERE r_reason_desc IS NOT NULL
    LIMIT 5
)
SELECT
    u.year,
    u.customer_id,
    u.net_loss,
    u.source,
    r.r_reason_id
FROM union_all u
CROSS JOIN small_reasons r
ORDER BY u.year DESC, u.net_loss DESC
LIMIT 100
