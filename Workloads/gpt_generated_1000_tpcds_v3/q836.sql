WITH per_item_year AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        d.d_year,
        d.d_date_sk AS date_sk,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_total,
        SUM(cr.cr_return_amt_inc_tax) AS catalog_return_total,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM store_returns sr
    INNER JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    INNER JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_manufact = 'n stcallyought'
      AND i.i_class = 'toddlers'
      AND cp.cp_catalog_page_number = 11
      AND hd.hd_vehicle_count >= 2
      AND inv.inv_quantity_on_hand > 0
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, d.d_year, d.d_date_sk
)
SELECT
    pi.d_year,
    pi.i_brand,
    SUM(pi.store_return_total) AS total_store_return,
    SUM(pi.catalog_return_total) AS total_catalog_return,
    SUM(pi.total_quantity_on_hand) AS total_quantity_on_hand,
    AVG(pi.store_return_total) AS avg_store_return,
    (SUM(pi.store_return_total) - SUM(pi.catalog_return_total)) AS net_loss
FROM per_item_year pi
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm
    INNER JOIN catalog_returns cr
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_item_sk = pi.i_item_sk
      AND cr.cr_returned_date_sk = pi.date_sk
      AND sm.sm_carrier = 'UPS'
)
GROUP BY pi.d_year, pi.i_brand
HAVING SUM(pi.store_return_total) > 1000
ORDER BY net_loss DESC
LIMIT 100
