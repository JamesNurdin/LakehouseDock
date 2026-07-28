WITH base AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        sr.sr_item_sk,
        i.i_category,
        i.i_brand,
        d1.d_year AS return_year,
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_net_loss AS catalog_net_loss,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cc.cc_name AS call_center_name,
        cp.cp_type AS catalog_page_type,
        sm.sm_type AS ship_mode_type,
        r.r_reason_desc,
        (
            SELECT AVG(inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_item_sk = i.i_item_sk
        ) AS avg_inventory_qty
    FROM store_returns sr
    JOIN date_dim d1
        ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t1
        ON sr.sr_return_time_sk = t1.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    -- catalog_returns path
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d2
        ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2
        ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    -- inventory path (same warehouse and date as store return)
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d1.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    -- optional link to web_returns for anti‑join later
    LEFT JOIN web_returns wr_chk
        ON wr_chk.wr_item_sk = i.i_item_sk
        AND wr_chk.wr_returned_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
)
SELECT * FROM (
    -- Store‑level aggregation (with anti‑join to exclude items also returned via web)
    SELECT
        CAST(base.sr_store_sk AS BIGINT)        AS entity_id,
        base.s_store_name                         AS entity_name,
        'store'                                   AS entity_type,
        base.return_year                         AS year,
        SUM(base.store_net_loss + base.catalog_net_loss) AS total_net_loss,
        COUNT(*)                                 AS return_cnt,
        AVG(base.avg_inventory_qty)              AS avg_inventory_qty
    FROM base
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = base.sr_item_sk
          AND wr2.wr_returned_date_sk = base.return_date_sk
    )
    GROUP BY base.sr_store_sk, base.s_store_name, base.return_year

    UNION ALL

    -- Warehouse‑level aggregation (no anti‑join)
    SELECT
        CAST(base.w_warehouse_sk AS BIGINT)      AS entity_id,
        base.w_warehouse_name                     AS entity_name,
        'warehouse'                               AS entity_type,
        base.return_year                         AS year,
        SUM(base.store_net_loss + base.catalog_net_loss) AS total_net_loss,
        COUNT(*)                                 AS return_cnt,
        NULL                                     AS avg_inventory_qty
    FROM base
    GROUP BY base.w_warehouse_sk, base.w_warehouse_name, base.return_year
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
