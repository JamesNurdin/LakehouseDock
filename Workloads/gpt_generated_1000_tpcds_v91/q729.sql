WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returning_customer_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_tax,
        cr.cr_return_ship_cost
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_current_week = 'N'
      AND d.d_year = 2001
      AND d.d_date_id LIKE 'AAAA%'
),

detail AS (
    SELECT
        b.cr_returned_date_sk,
        b.cr_returning_customer_sk,
        b.cr_reason_sk,
        t.metric_key,
        t.metric_value
    FROM base b
    CROSS JOIN UNNEST(
        map(
            ARRAY['quantity','amount','net_loss'],
            ARRAY[
                CAST(b.cr_return_quantity AS double),
                CAST(b.cr_return_amount AS double),
                CAST(b.cr_net_loss AS double)
            ]
        )
    ) AS t (metric_key, metric_value)
),

customer_agg AS (
    SELECT
        'customer' AS category,
        b.cr_returning_customer_sk AS id,
        SUM(b.cr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(b.cr_net_loss) > (SELECT AVG(cr_net_loss) FROM base) THEN 'high'
            ELSE 'low'
        END AS loss_level
    FROM base b
    GROUP BY b.cr_returning_customer_sk
    HAVING COUNT(*) > 5
),

reason_agg AS (
    SELECT
        'reason' AS category,
        b.cr_reason_sk AS id,
        SUM(b.cr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(b.cr_net_loss) > (SELECT AVG(cr_net_loss) FROM base) THEN 'high'
            ELSE 'low'
        END AS loss_level
    FROM base b
    GROUP BY b.cr_reason_sk
    HAVING COUNT(*) > 5
)

SELECT DISTINCT
    ca.category,
    ca.id,
    ca.total_loss,
    ca.return_cnt,
    ca.loss_level,
    (SELECT COUNT(*)
     FROM detail d
     WHERE d.cr_returning_customer_sk = ca.id
       AND d.metric_key = 'quantity'
       AND d.metric_value > 10) AS high_quantity_returns
FROM customer_agg ca
WHERE EXISTS (
    SELECT 1
    FROM detail d
    WHERE d.cr_returning_customer_sk = ca.id
      AND d.metric_key = 'net_loss'
      AND d.metric_value > 0
)

UNION

SELECT DISTINCT
    ra.category,
    ra.id,
    ra.total_loss,
    ra.return_cnt,
    ra.loss_level,
    (SELECT COUNT(*)
     FROM detail d
     WHERE d.cr_reason_sk = ra.id
       AND d.metric_key = 'quantity'
       AND d.metric_value > 10) AS high_quantity_returns
FROM reason_agg ra
WHERE EXISTS (
    SELECT 1
    FROM detail d
    WHERE d.cr_reason_sk = ra.id
      AND d.metric_key = 'net_loss'
      AND d.metric_value > 0
)

ORDER BY total_loss DESC
LIMIT 100
