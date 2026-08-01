WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
base_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_category_id,
        i.i_class,
        i.i_units,
        i.i_brand,
        i.i_current_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_time_sk,
        td.t_hour,
        sm.sm_ship_mode_sk,
        sm.sm_type AS ship_mode_type,
        cp.cp_catalog_number,
        r_cat.r_reason_desc AS catalog_reason_desc,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        s.s_store_name,
        r_store.r_reason_desc AS store_reason_desc,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        inv_agg.total_qty_on_hand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
    LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_units = 'Dozen'
      AND ws.ws_quantity > 1
      AND td.t_hour BETWEEN 9 AND 12
      AND sm.sm_ship_mode_sk IN (1, 5)
),
grouped AS (
    SELECT
        bd.i_category,
        bd.s_store_name AS store_name,
        bd.catalog_reason_desc,
        bd.store_reason_desc,
        SUM(bd.ws_net_profit) AS total_ws_profit,
        SUM(bd.sr_net_loss) AS total_sr_net_loss,
        SUM(COALESCE(cr2.cr_net_loss, 0)) AS total_cr_net_loss,
        SUM(bd.total_qty_on_hand) AS total_inventory_qty,
        SUM(bd.sr_return_quantity) AS total_return_quantity
    FROM base_data bd
    LEFT JOIN catalog_returns cr2 ON cr2.cr_item_sk = bd.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = bd.i_item_sk
          AND cr3.cr_return_amount > 1000
    )
    GROUP BY GROUPING SETS (
        (bd.i_category, bd.s_store_name, bd.catalog_reason_desc, bd.store_reason_desc),
        (bd.i_category, bd.s_store_name),
        (bd.i_category),
        ()
    )
)
SELECT
    i_category,
    store_name,
    catalog_reason_desc,
    store_reason_desc,
    total_ws_profit,
    total_sr_net_loss,
    total_cr_net_loss,
    total_inventory_qty,
    total_return_quantity,
    RANK() OVER (PARTITION BY i_category ORDER BY total_ws_profit DESC) AS profit_rank,
    CASE WHEN total_ws_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag,
    (SELECT SUM(sr2.sr_return_quantity)
     FROM store_returns sr2
     JOIN item i2 ON sr2.sr_item_sk = i2.i_item_sk
     WHERE i2.i_category = grouped.i_category) AS total_return_qty_by_category
FROM grouped
ORDER BY i_category, profit_rank
LIMIT 100
