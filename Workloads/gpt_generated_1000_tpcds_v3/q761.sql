WITH item_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_color,
        i.i_category,
        s.s_store_sk,
        s.s_store_id,
        SUM(cs.cs_net_profit) AS cs_net_profit,
        SUM(ws.ws_net_profit) AS ws_net_profit,
        SUM(sr.sr_net_loss) AS sr_net_loss,
        SUM(cs.cs_ext_sales_price) AS cs_sales,
        SUM(ws.ws_ext_sales_price) AS ws_sales,
        SUM(sr.sr_return_amt) AS sr_returns,
        COUNT(*) FILTER (WHERE cs.cs_order_number IS NOT NULL) AS cs_orders,
        COUNT(*) FILTER (WHERE ws.ws_order_number IS NOT NULL) AS ws_orders,
        COUNT(*) FILTER (WHERE sr.sr_ticket_number IS NOT NULL) AS sr_returns_cnt
    FROM catalog_sales cs
    JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca_sr_addr ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN date_dim d_sr_returned ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_cs_sold.d_holiday = 'Y'
      AND i.i_color IN ('Red', 'Blue')
      AND s.s_state = 'CA'
      AND w.w_gmt_offset = -5.00
      AND d_cs_sold.d_year = 2001
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_color,
        i.i_category,
        s.s_store_sk,
        s.s_store_id
)
SELECT
    i_sa.i_item_id,
    i_sa.i_product_name,
    i_sa.i_color,
    i_sa.i_category,
    i_sa.s_store_id,
    i_sa.cs_net_profit,
    i_sa.ws_net_profit,
    i_sa.sr_net_loss,
    (i_sa.cs_net_profit + i_sa.ws_net_profit - i_sa.sr_net_loss) AS total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY i_sa.i_category ORDER BY (i_sa.cs_net_profit + i_sa.ws_net_profit - i_sa.sr_net_loss) DESC) AS category_rank,
    (SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001) AS avg_yearly_cs_profit,
    CASE WHEN EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = i_sa.i_item_sk
          AND inv2.inv_quantity_on_hand > 1000
    ) THEN 'High Inventory' ELSE 'Low Inventory' END AS inventory_status
FROM item_sales_agg i_sa
WHERE (i_sa.cs_net_profit + i_sa.ws_net_profit - i_sa.sr_net_loss) > (
    SELECT AVG(cs3.cs_net_profit)
    FROM catalog_sales cs3
    JOIN date_dim d3 ON cs3.cs_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = 2001
)
ORDER BY total_net_profit DESC
LIMIT 100
