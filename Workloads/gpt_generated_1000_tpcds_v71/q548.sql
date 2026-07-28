WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_ship_cost,
        i.i_brand,
        i.i_category,
        i.i_wholesale_cost,
        d.d_date,
        d.d_year,
        d.d_current_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND i.i_wholesale_cost >= 5
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND d.d_current_year = 'Y'
),
agg AS (
    SELECT
        d_year AS year,
        i_brand AS brand,
        i_category AS category,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_net_loss) AS sum_net_loss
    FROM filtered
    GROUP BY GROUPING SETS (
        (d_year, i_brand, i_category),
        (d_year, i_brand),
        (d_year),
        ()
    )
)
SELECT
    year,
    brand,
    category,
    sum_return_amount,
    sum_net_loss,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY sum_net_loss DESC) AS brand_net_loss_rank
FROM agg
WHERE year IS NOT NULL
ORDER BY year DESC, brand_net_loss_rank
LIMIT 100
