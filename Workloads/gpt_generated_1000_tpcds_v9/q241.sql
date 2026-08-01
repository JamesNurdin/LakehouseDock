WITH joined_data AS (
    SELECT
        wh.w_warehouse_id,
        wh.w_city,
        cp.cp_type,
        cs.cs_net_profit AS catalog_sales_profit,
        cr.cr_net_loss AS catalog_return_loss,
        ws.ws_net_profit AS web_sales_profit,
        wr.wr_net_loss AS web_return_loss,
        i.inv_quantity_on_hand,
        cs.cs_quantity AS catalog_quantity,
        ws.ws_quantity AS web_quantity,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = wh.w_warehouse_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = wh.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    WHERE cp.cp_type = 'monthly'
      AND wh.w_state = 'CA'
      AND i.inv_quantity_on_hand > 0
      AND cs.cs_net_profit > 0
),
warehouse_agg AS (
    SELECT
        w_warehouse_id,
        w_city,
        cp_type,
        SUM(catalog_sales_profit) AS total_catalog_sales_profit,
        SUM(catalog_return_loss) AS total_catalog_return_loss,
        SUM(web_sales_profit) AS total_web_sales_profit,
        SUM(web_return_loss) AS total_web_return_loss,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        SUM(catalog_quantity) AS total_catalog_quantity_sold,
        SUM(web_quantity) AS total_web_quantity_sold,
        SUM(catalog_sales_amount) AS total_catalog_sales_amount,
        SUM(web_sales_amount) AS total_web_sales_amount
    FROM joined_data
    GROUP BY w_warehouse_id, w_city, cp_type
),
final_agg AS (
    SELECT
        w_warehouse_id,
        w_city,
        cp_type,
        total_catalog_sales_profit,
        total_catalog_return_loss,
        total_web_sales_profit,
        total_web_return_loss,
        total_inventory_on_hand,
        total_catalog_quantity_sold,
        total_web_quantity_sold,
        total_catalog_sales_amount,
        total_web_sales_amount,
        (total_catalog_sales_profit + total_web_sales_profit - total_catalog_return_loss - total_web_return_loss) AS net_profit,
        (total_catalog_sales_amount + total_web_sales_amount) AS total_sales_amount
    FROM warehouse_agg
    WHERE (total_catalog_sales_profit + total_web_sales_profit - total_catalog_return_loss - total_web_return_loss) > 10000
)
SELECT
    w_warehouse_id,
    w_city,
    cp_type,
    net_profit,
    total_sales_amount,
    total_inventory_on_hand,
    total_catalog_quantity_sold,
    total_web_quantity_sold,
    RANK() OVER (ORDER BY net_profit DESC) AS profit_rank,
    SUM(net_profit) OVER (PARTITION BY cp_type) AS profit_sum_by_type
FROM final_agg
ORDER BY profit_rank
LIMIT 100
