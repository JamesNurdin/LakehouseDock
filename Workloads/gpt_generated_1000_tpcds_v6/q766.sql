WITH catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        hd.hd_demo_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND inv.inv_quantity_on_hand > 200
    GROUP BY d.d_year, hd.hd_demo_sk
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        hd.hd_demo_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        'web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, hd.hd_demo_sk
),
combined AS (
    SELECT year, hd_demo_sk, total_return_amount, source FROM catalog_returns_agg
    UNION ALL
    SELECT year, hd_demo_sk, total_return_amount, source FROM web_returns_agg
)
SELECT
    year,
    hd_demo_sk,
    total_return_amount,
    source,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_return_amount DESC) AS rank_within_year
FROM combined
ORDER BY year, rank_within_year
LIMIT 100
