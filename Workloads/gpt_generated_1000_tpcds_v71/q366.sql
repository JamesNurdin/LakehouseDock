WITH enriched_returns AS (
    SELECT
        i.i_category,
        t.t_am_pm,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_rec_end_date >= DATE '2000-01-01'
)
SELECT DISTINCT
    category,
    am_pm,
    total_return_amount,
    total_return_qty
FROM (
    SELECT
        er.i_category AS category,
        er.t_am_pm AS am_pm,
        SUM(er.cr_return_amount) AS total_return_amount,
        SUM(er.cr_return_quantity) AS total_return_qty
    FROM enriched_returns er
    WHERE er.t_am_pm = 'AM' AND er.cr_return_amount > 20
    GROUP BY er.i_category, er.t_am_pm

    UNION ALL

    SELECT
        er.i_category AS category,
        er.t_am_pm AS am_pm,
        SUM(er.cr_return_amount) AS total_return_amount,
        SUM(er.cr_return_quantity) AS total_return_qty
    FROM enriched_returns er
    WHERE er.t_am_pm = 'PM' AND er.cr_return_amount <= 20
    GROUP BY er.i_category, er.t_am_pm
) AS unioned
ORDER BY category, am_pm DESC
LIMIT 100
