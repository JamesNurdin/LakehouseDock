/* goal: Compare distinct return amounts by item and ship mode (if applicable) across catalog and store channels for the year 2001, showing the channel source and ordering by year and amount */
WITH catalog_ret AS (
    SELECT DISTINCT
        i.i_item_id      AS item_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        cr.cr_return_amount AS return_amount,
        d.d_year          AS year,
        'catalog'         AS channel
    FROM catalog_returns cr
    JOIN date_dim d      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i          ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 0
),
store_ret AS (
    SELECT DISTINCT
        i.i_item_id      AS item_id,
        NULL              AS ship_mode_id,
        sr.sr_return_amt AS return_amount,
        d.d_year          AS year,
        'store'           AS channel
    FROM store_returns sr
    JOIN date_dim d      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i          ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_amt > 0
)
SELECT
    item_id,
    ship_mode_id,
    return_amount,
    year,
    channel
FROM (
    SELECT item_id, ship_mode_id, return_amount, year, channel FROM catalog_ret
    UNION ALL
    SELECT item_id, ship_mode_id, return_amount, year, channel FROM store_ret
) AS combined
ORDER BY year DESC, return_amount DESC
LIMIT 100
