WITH cat_ret AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        SUM(cr.cr_return_amount) AS cat_return_amount,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk
),
store_ret AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_reason_sk,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS store_return_amount,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_reason_sk,
        sr.sr_store_sk
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_reason_sk,
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_reason_sk,
        wr.wr_web_page_sk
),
inv_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk,
        inv.inv_item_sk
)
SELECT
    d.d_date,
    i.i_category,
    r.r_reason_desc,
    SUM(COALESCE(cat.cat_return_amount, 0) + COALESCE(store.store_return_amount, 0) + COALESCE(web.web_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cat.cat_return_cnt, 0) + COALESCE(store.store_return_cnt, 0) + COALESCE(web.web_return_cnt, 0)) AS total_return_cnt,
    AVG(inv.avg_qty_on_hand) AS avg_inventory_qty,
    MIN(i.i_current_price) AS min_price,
    MAX(i.i_current_price) AS max_price
FROM date_dim d
JOIN cat_ret cat ON cat.cr_returned_date_sk = d.d_date_sk
JOIN store_ret store ON store.sr_returned_date_sk = d.d_date_sk
JOIN web_ret web ON web.wr_returned_date_sk = d.d_date_sk
JOIN item i ON i.i_item_sk = cat.cr_item_sk
    AND i.i_item_sk = store.sr_item_sk
    AND i.i_item_sk = web.wr_item_sk
JOIN reason r ON r.r_reason_sk = cat.cr_reason_sk
    AND r.r_reason_sk = store.sr_reason_sk
    AND r.r_reason_sk = web.wr_reason_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cat.cr_catalog_page_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = cat.cr_ship_mode_sk
JOIN warehouse w ON w.w_warehouse_sk = cat.cr_warehouse_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = cat.cr_refunded_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = cat.cr_refunded_hdemo_sk
JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN time_dim t ON t.t_time_sk = cat.cr_returned_time_sk
JOIN store s ON s.s_store_sk = store.sr_store_sk
JOIN web_page wp ON wp.wp_web_page_sk = web.wr_web_page_sk
LEFT JOIN inv_agg inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND i.i_brand = 'Brand#23'
  AND r.r_reason_desc LIKE '%not%liked%'
  AND hd.hd_buy_potential = '1001-5000'
  AND cp.cp_department = 'Books'
  AND sm.sm_type = 'AIR'
  AND wp.wp_type = 'HOME'
  AND EXISTS (
        SELECT 1
        FROM warehouse w2
        WHERE w2.w_warehouse_sk = cat.cr_warehouse_sk
          AND w2.w_state = 'CA'
    )
GROUP BY d.d_date, i.i_category, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
