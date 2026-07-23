WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        w.w_warehouse_name,
        d_sold_cs.d_year AS sales_year,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_net_loss,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_profit,
        SUM(ia.total_quantity_on_hand) AS total_inventory_on_hand
    FROM inv_agg ia
    JOIN item i ON ia.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold_cs ON cs.cs_sold_date_sk = d_sold_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d_sold_ss ON ss.ss_sold_date_sk = d_sold_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_return_sr ON sr.sr_returned_date_sk = d_return_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sold_ws ON ws.ws_sold_date_sk = d_sold_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    WHERE
        d_sold_cs.d_year = 2001
        AND d_sold_ss.d_year = 2001
        AND d_sold_ws.d_year = 2001
        AND i.i_category = 'Electronics'
        AND s.s_state = 'CA'
        AND c_bill.c_birth_year BETWEEN 1950 AND 1960
        AND t_cs.t_hour BETWEEN 9 AND 17
        AND cc.cc_gmt_offset = -5.00
        AND w.w_country = 'United States'
        AND ca_bill.ca_location_type = 'S'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        w.w_warehouse_name,
        d_sold_cs.d_year
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    i_brand,
    sales_year,
    w_warehouse_name,
    catalog_net_profit,
    store_net_profit,
    web_net_profit,
    returns_net_loss,
    total_net_profit,
    total_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_profit DESC) AS category_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
