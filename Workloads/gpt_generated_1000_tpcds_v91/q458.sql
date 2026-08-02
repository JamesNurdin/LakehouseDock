WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_return_quantity,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        CASE
            WHEN cr.cr_return_amount >= 100 THEN 'High'
            ELSE 'Low'
        END AS return_amount_category
    FROM catalog_returns cr
    FULL OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE
        (cr.cr_return_amount > 50 OR cr.cr_return_amount IS NULL)
        AND (d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31' OR d.d_date IS NULL)
        AND (d.d_moy IN (1, 8, 12) OR d.d_moy IS NULL)
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        return_amount_category,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cr_fee) AS total_fee,
        SUM(cr_return_quantity) AS total_quantity
    FROM base
    GROUP BY ROLLUP (d_year, d_month_seq, return_amount_category)
)
SELECT
    d_year,
    d_month_seq,
    return_amount_category,
    distinct_orders,
    total_return_amount,
    total_net_loss,
    total_fee,
    total_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
WHERE d_year IS NOT NULL
ORDER BY d_year, d_month_seq
LIMIT 100
