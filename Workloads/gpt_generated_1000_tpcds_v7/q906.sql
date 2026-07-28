WITH base AS (
    SELECT
        d.d_year,
        i.i_class,
        i.i_units,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1905 AND 1910
      AND i.i_class IN ('accessories', 'pants', 'sports-apparel')
      AND sr.sr_fee > 30
),
agg AS (
    SELECT
        d_year,
        i_class,
        i_units,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_qty
    FROM base
    GROUP BY d_year, i_class, i_units
)
SELECT
    d_year,
    i_class,
    i_units,
    total_return_amount,
    avg_return_qty,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS return_rank,
    CASE
        WHEN total_return_amount > 5000 THEN 'HIGH'
        WHEN total_return_amount > 2000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level
FROM agg
ORDER BY d_year, return_rank
LIMIT 100
