WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        cp.cp_department,
        w.w_state,
        r.r_reason_desc,
        s.s_store_name,
        p.p_promo_name,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        inv.inv_quantity_on_hand,
        cr.cr_order_number,
        ws.ws_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
),
aggregated AS (
    SELECT
        d_year,
        i_brand,
        cp_department,
        cr_return_amount AS total_return_amount,
        ws_net_profit AS total_net_profit,
        inv_quantity_on_hand AS total_inventory_on_hand,
        cr_order_number AS return_order_id,
        ws_order_number AS sales_order_id
    FROM base
    WHERE d_year BETWEEN 2000 AND 2002                         -- filter 1
      AND w_state IN ('MN', 'OH')                               -- filter 2
      AND i_brand LIKE 'brand%'                                 -- filter 3
)
SELECT
    d_year,
    i_brand,
    cp_department,
    SUM(total_return_amount) AS sum_return_amount,
    SUM(total_net_profit) AS sum_net_profit,
    SUM(total_inventory_on_hand) AS sum_inventory_on_hand,
    COUNT(DISTINCT return_order_id) AS distinct_return_orders,
    COUNT(DISTINCT sales_order_id) AS distinct_sales_orders
FROM aggregated
GROUP BY GROUPING SETS (
    (d_year, i_brand, cp_department),
    (d_year, i_brand),
    (d_year),
    ()
)
HAVING SUM(total_return_amount) > 1000
ORDER BY d_year DESC, i_brand, cp_department
LIMIT 100
