WITH
    sampled_inventory AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    joined_data AS (
        SELECT
            i.i_category,
            i.i_brand,
            i.i_current_price,
            hd.hd_income_band_sk,
            cs.cs_order_number,
            cs.cs_net_profit AS catalog_net_profit,
            cr.cr_return_quantity AS catalog_return_qty,
            cr.cr_net_loss AS catalog_return_loss,
            ws.ws_order_number,
            ws.ws_net_profit AS web_net_profit,
            w.w_state,
            sm.sm_type,
            cp.cp_department,
            ss.ss_ticket_number,
            ss.ss_net_profit AS store_net_profit,
            sr.sr_return_quantity AS store_return_qty,
            sr.sr_net_loss AS store_return_loss,
            inv.inv_quantity_on_hand
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
        FULL OUTER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        FULL OUTER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                          AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
        WHERE i.i_class_id = 14
          AND w.w_state = 'CA'
          AND sm.sm_type = 'AIR'
          AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    ),
    aggregated AS (
        SELECT
            i_category,
            i_brand,
            SUM(catalog_net_profit) AS total_catalog_profit,
            SUM(web_net_profit) AS total_web_profit,
            SUM(store_net_profit) AS total_store_profit,
            SUM(catalog_return_qty) AS total_catalog_return_qty,
            SUM(store_return_qty) AS total_store_return_qty,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM joined_data
        GROUP BY i_category, i_brand
    )
SELECT
    a.i_category,
    a.i_brand,
    a.total_catalog_profit,
    a.total_web_profit,
    a.total_store_profit,
    a.total_on_hand,
    (
        SELECT COUNT(*)
        FROM (
            SELECT cs_order_number FROM catalog_sales
            EXCEPT
            SELECT cr_order_number FROM catalog_returns
        ) AS diff
    ) AS orders_without_returns,
    (a.total_catalog_profit + a.total_web_profit + a.total_store_profit) / 3.0 AS avg_channel_profit
FROM aggregated a
WHERE a.total_catalog_profit > 10000
  AND a.total_on_hand > 0
  AND (a.total_catalog_return_qty + a.total_store_return_qty) < 500
ORDER BY avg_channel_profit DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
