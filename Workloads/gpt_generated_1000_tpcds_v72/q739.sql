WITH
    ws_year AS (
        SELECT
            ws.ws_item_sk,
            d.d_year,
            SUM(ws.ws_net_profit)               AS ws_net_profit,
            SUM(ws.ws_ext_sales_price)          AS ws_sales_amount,
            COUNT(*)                            AS ws_txn_cnt
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY ws.ws_item_sk, d.d_year
    ),
    sr_year AS (
        SELECT
            sr.sr_item_sk,
            d.d_year,
            SUM(sr.sr_net_loss)                 AS sr_net_loss,
            COUNT(*)                           AS sr_txn_cnt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY sr.sr_item_sk, d.d_year
    ),
    cr_year AS (
        SELECT
            cr.cr_item_sk,
            d.d_year,
            SUM(cr.cr_net_loss)                 AS cr_net_loss,
            COUNT(*)                           AS cr_txn_cnt
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        GROUP BY cr.cr_item_sk, d.d_year
    ),
    inv_year AS (
        SELECT
            inv.inv_item_sk,
            d.d_year,
            AVG(inv.inv_quantity_on_hand)       AS avg_qty_on_hand
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        GROUP BY inv.inv_item_sk, d.d_year
    ),
    ship_mode_per_item AS (
        SELECT cr.cr_item_sk, MAX(cr.cr_ship_mode_sk) AS ship_mode_sk
        FROM catalog_returns cr
        GROUP BY cr.cr_item_sk
    ),
    warehouse_per_item AS (
        SELECT cr.cr_item_sk, MAX(cr.cr_warehouse_sk) AS warehouse_sk
        FROM catalog_returns cr
        GROUP BY cr.cr_item_sk
    ),
    call_center_per_item AS (
        SELECT cr.cr_item_sk, MAX(cr.cr_call_center_sk) AS call_center_sk
        FROM catalog_returns cr
        GROUP BY cr.cr_item_sk
    ),
    store_per_item AS (
        SELECT sr.sr_item_sk, MAX(sr.sr_store_sk) AS store_sk
        FROM store_returns sr
        GROUP BY sr.sr_item_sk
    ),
    web_page_per_item AS (
        SELECT ws.ws_item_sk, MAX(ws.ws_web_page_sk) AS web_page_sk
        FROM web_sales ws
        GROUP BY ws.ws_item_sk
    ),
    hd_bill_per_item AS (
        SELECT ws.ws_item_sk, MAX(ws.ws_bill_hdemo_sk) AS bill_hdemo_sk
        FROM web_sales ws
        GROUP BY ws.ws_item_sk
    ),
    item_details AS (
        SELECT i.i_item_sk,
               i.i_category,
               i.i_brand,
               i.i_current_price
        FROM item i
    )
SELECT
    i.i_category,
    y.d_year,
    COALESCE(ws.ws_net_profit, 0)            AS total_web_profit,
    COALESCE(sr.sr_net_loss, 0)              AS total_store_return_loss,
    COALESCE(cr.cr_net_loss, 0)              AS total_catalog_return_loss,
    COALESCE(inv.avg_qty_on_hand, 0)         AS avg_inventory_qty,
    CASE
        WHEN COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0) - COALESCE(cr.cr_net_loss, 0) > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END                                      AS profit_indicator,
    AVG(ws.ws_net_profit) OVER (PARTITION BY i.i_category) AS avg_profit_per_category,
    RANK() OVER (ORDER BY COALESCE(ws.ws_net_profit, 0) DESC) AS profit_rank,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    w.w_warehouse_name,
    cc.cc_name,
    s.s_store_name,
    wp.wp_url
FROM item_details i
LEFT JOIN ws_year ws      ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN sr_year sr      ON i.i_item_sk = sr.sr_item_sk AND ws.d_year = sr.d_year
LEFT JOIN cr_year cr      ON i.i_item_sk = cr.cr_item_sk AND ws.d_year = cr.d_year
LEFT JOIN inv_year inv    ON i.i_item_sk = inv.inv_item_sk AND ws.d_year = inv.d_year
LEFT JOIN date_dim y      ON ws.d_year = y.d_year
LEFT JOIN ship_mode_per_item smi ON i.i_item_sk = smi.cr_item_sk
LEFT JOIN ship_mode sm          ON smi.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse_per_item wpi ON i.i_item_sk = wpi.cr_item_sk
LEFT JOIN warehouse w            ON wpi.warehouse_sk = w.w_warehouse_sk
LEFT JOIN call_center_per_item cci ON i.i_item_sk = cci.cr_item_sk
LEFT JOIN call_center cc           ON cci.call_center_sk = cc.cc_call_center_sk
LEFT JOIN store_per_item spi      ON i.i_item_sk = spi.sr_item_sk
LEFT JOIN store s                 ON spi.store_sk = s.s_store_sk
LEFT JOIN web_page_per_item wpi2 ON i.i_item_sk = wpi2.ws_item_sk
LEFT JOIN web_page wp            ON wpi2.web_page_sk = wp.wp_web_page_sk
LEFT JOIN hd_bill_per_item hdbi ON i.i_item_sk = hdbi.ws_item_sk
LEFT JOIN household_demographics hd_bill ON hdbi.bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN income_band ib               ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_item_sk = i.i_item_sk
)
LIMIT 100
