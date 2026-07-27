WITH base AS (
    SELECT
        cc.cc_call_center_id            AS cc_call_center_id,
        w.w_warehouse_id                AS w_warehouse_id,
        i.i_item_id                     AS i_item_id,
        i.i_category                    AS i_category,
        cp.cp_department                AS cp_department,
        sm.sm_type                      AS sm_type,
        cs.cs_order_number              AS order_number,
        cs.cs_net_profit                AS catalog_net_profit,
        ws.ws_net_profit                AS web_net_profit,
        cr.cr_net_loss                  AS catalog_return_loss,
        wr.wr_net_loss                  AS web_return_loss,
        sr.sr_net_loss                  AS store_return_loss
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_order_number = cs.cs_order_number
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    WHERE
        cc.cc_rec_start_date >= DATE '2001-01-01'
        AND w.w_country = 'United States'
        AND w.w_street_type IN ('Street', 'Drive')
        AND i.i_category = 'Electronics'
        AND cp.cp_department = 'Sports'
        AND EXISTS (
            SELECT 1 FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
              AND sr2.sr_return_quantity > 0
        )
)
SELECT
    cc_call_center_id,
    w_warehouse_id,
    COUNT(DISTINCT i_item_id)                     AS distinct_items_sold,
    SUM(catalog_net_profit + web_net_profit)      AS total_net_profit,
    SUM(catalog_return_loss + web_return_loss + store_return_loss) AS total_net_loss,
    AVG((catalog_net_profit + web_net_profit) - (catalog_return_loss + web_return_loss + store_return_loss)) AS avg_profit_per_item
FROM base
GROUP BY
    cc_call_center_id,
    w_warehouse_id
HAVING
    SUM(catalog_net_profit + web_net_profit) > 100000
ORDER BY
    total_net_profit DESC
LIMIT 20
