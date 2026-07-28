WITH base_data AS (
    SELECT
        cc.cc_state,
        i.i_brand,
        i.i_category,
        cp.cp_department,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        inv.inv_quantity_on_hand,
        r_cr.r_reason_desc AS catalog_return_reason,
        r_wr.r_reason_desc AS web_return_reason,
        td_cs.t_time AS cs_time,
        td_cr.t_time AS cr_time,
        td_ws.t_time AS ws_time,
        td_wr.t_time AS wr_time
    FROM catalog_sales cs
    JOIN time_dim td_cs
      ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN time_dim td_cr
      ON cr.cr_returned_time_sk = td_cr.t_time_sk
    LEFT JOIN web_sales ws
      ON ws.ws_order_number = cs.cs_order_number
     AND ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN time_dim td_ws
      ON ws.ws_sold_time_sk = td_ws.t_time_sk
    LEFT JOIN web_page wp_ws
      ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
    LEFT JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN time_dim td_wr
      ON wr.wr_returned_time_sk = td_wr.t_time_sk
    LEFT JOIN web_page wp_wr
      ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_brand = 'BrandA'
      AND td_cs.t_time BETWEEN 8 AND 12
      AND cp.cp_department = 'Books'
      AND i.i_category IN (
          SELECT i2.i_category
          FROM item i2
          WHERE i2.i_brand = 'BrandA'
            AND i2.i_category NOT LIKE '%Misc%'
      )
),
agg_data AS (
    SELECT
        cc_state,
        i_brand,
        cp_department,
        SUM(cs_net_paid) AS total_sales_net_paid,
        AVG(cs_net_profit) AS avg_sales_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_net_loss) AS total_return_loss,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        (
            SELECT MAX(i3.i_current_price)
            FROM item i3
            WHERE i3.i_brand = base_data.i_brand
        ) AS max_item_price
    FROM base_data
    GROUP BY ROLLUP (cc_state, i_brand, cp_department)
    HAVING SUM(cs_net_paid) > 1000
)
SELECT
    cc_state,
    i_brand,
    cp_department,
    total_sales_net_paid,
    avg_sales_profit,
    distinct_orders,
    total_return_qty,
    total_return_loss,
    total_web_sales,
    total_inventory_on_hand,
    max_item_price,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_sales_net_paid DESC) AS brand_rank
FROM agg_data
ORDER BY total_sales_net_paid DESC
LIMIT 100
