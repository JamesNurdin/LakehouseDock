WITH base AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        t.t_hour AS hour,
        ws_site.web_name AS web_name,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        SUM(cs.cs_net_profit + ws.ws_net_profit - sr.sr_net_loss - wr.wr_net_loss) AS net_profit,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    JOIN web_sales ws2 ON wr.wr_item_sk = ws2.ws_item_sk AND wr.wr_order_number = ws2.ws_order_number
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY
        w.w_warehouse_name,
        t.t_hour,
        ws_site.web_name
)
SELECT
    warehouse_name,
    hour,
    web_name,
    total_catalog_sales,
    total_web_sales,
    total_store_returns,
    total_web_returns,
    net_profit,
    CASE WHEN net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY warehouse_name ORDER BY net_profit DESC) AS profit_rank,
    total_inventory_qty
FROM base
ORDER BY net_profit DESC
LIMIT 100
