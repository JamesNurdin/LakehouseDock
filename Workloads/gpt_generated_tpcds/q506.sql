/*
  Returns analysis – total return amount and quantity by product category per month for the year 2022,
  together with month‑over‑month change using a window function.
*/
WITH monthly_returns AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_return_amount)        AS total_return_amount,
        SUM(cr.cr_return_quantity)      AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT
    mr.i_category,
    mr.d_year,
    mr.d_moy                     AS month,
    mr.total_return_amount,
    mr.total_return_quantity,
    mr.total_return_amount - LAG(mr.total_return_amount) OVER (
        PARTITION BY mr.i_category
        ORDER BY mr.d_year, mr.d_moy
    )                            AS diff_prev_month_amount,
    mr.total_return_quantity - LAG(mr.total_return_quantity) OVER (
        PARTITION BY mr.i_category
        ORDER BY mr.d_year, mr.d_moy
    )                            AS diff_prev_month_quantity
FROM monthly_returns mr
ORDER BY mr.total_return_amount DESC
LIMIT 20
