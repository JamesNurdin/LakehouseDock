WITH joined AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        w.w_state,
        cc.cc_name,
        cp.cp_catalog_page_number,
        wp.wp_type,
        ss.ss_net_profit            AS store_net_profit,
        cs.cs_net_profit            AS catalog_net_profit,
        ws.ws_net_profit            AS web_net_profit,
        wr.wr_net_loss              AS return_net_loss,
        inv.inv_quantity_on_hand    AS inventory_qty
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'BrandX'
      AND w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_catalog_page_number IN (1, 2, 3)
      AND wp.wp_type = 'A'
      AND cc.cc_name LIKE '%Center%'
)
SELECT
    i_item_id,
    d_year,
    w_state,
    SUM(catalog_net_profit)   AS total_catalog_profit,
    SUM(store_net_profit)     AS total_store_profit,
    SUM(web_net_profit)       AS total_web_profit,
    SUM(return_net_loss)      AS total_return_loss,
    SUM(inventory_qty)        AS total_inventory,
    (SUM(catalog_net_profit) + SUM(store_net_profit) + SUM(web_net_profit) - SUM(return_net_loss)) AS net_total_profit,
    (
        SELECT AVG(total_net)
        FROM (
            SELECT SUM(catalog_net_profit) + SUM(store_net_profit) + SUM(web_net_profit) - SUM(return_net_loss) AS total_net
            FROM joined
            GROUP BY i_item_id
        ) sub_avg
    ) AS avg_net_profit_all_items
FROM joined
GROUP BY i_item_id, d_year, w_state
HAVING SUM(catalog_net_profit) > 10000
ORDER BY net_total_profit DESC
LIMIT 100
