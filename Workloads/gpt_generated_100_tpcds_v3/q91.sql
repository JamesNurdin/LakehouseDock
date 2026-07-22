WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_id,
        w.w_state,
        d_sold.d_year,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                      AND ws.ws_bill_customer_sk = c.c_customer_sk
                      AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                        AND wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_wr_ret ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    JOIN time_dim t_wr_ret ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
    WHERE 
        d_sold.d_year = 2020
        AND w.w_state IN ('MO', 'OH', 'IN')
        AND i.i_current_price BETWEEN 20 AND 200
        AND cs.cs_quantity > 1
        AND ca.ca_country = 'United States'
        AND t.t_hour BETWEEN 9 AND 17
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
              AND cr.cr_item_sk = cs.cs_item_sk
              AND cr.cr_returned_date_sk = d_sold.d_date_sk
              AND cr.cr_return_amount > 0
        )
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_id,
        w.w_state,
        d_sold.d_year
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    w_warehouse_id,
    w_state,
    d_year,
    catalog_profit,
    web_profit,
    total_profit,
    total_quantity,
    total_inventory_on_hand,
    CASE
        WHEN total_profit > 10000 THEN 'High'
        WHEN total_profit > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier,
    RANK() OVER (PARTITION BY w_state ORDER BY total_profit DESC) AS state_profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
