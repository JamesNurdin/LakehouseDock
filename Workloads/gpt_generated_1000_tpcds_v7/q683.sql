WITH base AS (
    SELECT
        i.i_item_id,
        s.s_store_id,
        w.w_warehouse_id,
        p.p_promo_id,
        ss.ss_quantity            AS store_quantity,
        ss.ss_ext_sales_price     AS store_sales,
        ws.ws_quantity            AS web_quantity,
        ws.ws_ext_sales_price     AS web_sales,
        cr.cr_return_quantity     AS return_qty,
        cr.cr_return_amount       AS return_amount,
        inv.inv_quantity_on_hand  AS inv_quantity_on_hand
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.promotion p          ON p.p_item_sk = i.i_item_sk
    JOIN tpcds.store_sales ss       ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s              ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.warehouse w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws        ON ws.ws_item_sk = i.i_item_sk
                                    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_page cp      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.call_center cc      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.inventory inv       ON inv.inv_item_sk = i.i_item_sk
                                    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_zip = '78370'
      AND w.w_warehouse_sq_ft > 500000
      AND i.i_wholesale_cost BETWEEN 0.5 AND 2.0
      AND p.p_promo_name LIKE '%Clearance%'
      AND ss.ss_list_price > 100
      AND ws.ws_net_profit > 0
      AND cr.cr_return_amount > 1000
),
agg AS (
    SELECT
        i_item_id,
        SUM(store_sales)                         AS total_store_sales,
        SUM(web_sales)                           AS total_web_sales,
        SUM(return_amount)                       AS total_returns,
        AVG(inv_quantity_on_hand)                AS avg_inventory_on_hand,
        (SUM(store_sales) + SUM(web_sales) - SUM(return_amount))
            / NULLIF(SUM(store_sales) + SUM(web_sales), 0) AS net_sales_ratio
    FROM base
    GROUP BY i_item_id
    HAVING SUM(store_sales) > 5000
)
SELECT
    COUNT(*)                              AS num_items,
    AVG(total_store_sales)                AS avg_store_sales,
    AVG(total_web_sales)                  AS avg_web_sales,
    AVG(total_returns)                    AS avg_returns,
    AVG(net_sales_ratio)                  AS avg_net_sales_ratio
FROM agg
ORDER BY avg_net_sales_ratio DESC
LIMIT 100
