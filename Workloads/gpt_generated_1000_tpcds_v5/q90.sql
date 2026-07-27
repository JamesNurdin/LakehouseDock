WITH base AS (
   SELECT
       cp.cp_type,
       i.i_brand,
       w.w_warehouse_name,
       ss.ss_net_profit AS store_profit,
       ws.ws_net_profit AS web_profit,
       cr.cr_net_loss AS return_loss,
       ss.ss_ticket_number,
       ws.ws_order_number,
       cr.cr_order_number,
       ca_ss.ca_location_type AS sale_address_type,
       ca_ws_bill.ca_location_type AS web_bill_address_type,
       ca_cr_refund.ca_location_type AS refund_address_type,
       cd_ss.cd_gender AS sale_gender,
       cd_ws_bill.cd_gender AS web_bill_gender,
       cd_cr_refund.cd_gender AS refund_gender,
       hd_ss.hd_vehicle_count AS sale_vehicle_cnt,
       hd_ws_bill.hd_vehicle_count AS web_bill_vehicle_cnt,
       hd_cr_refund.hd_vehicle_count AS refund_vehicle_cnt,
       CASE 
           WHEN cr.cr_return_quantity IS NOT NULL THEN 'return'
           WHEN ws.ws_order_number IS NOT NULL THEN 'web_sale'
           ELSE 'store_sale'
       END AS transaction_category
   FROM catalog_page cp
   JOIN catalog_returns cr
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
       ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN item i
       ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN customer_address ca_cr_refund
       ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
   LEFT JOIN customer_demographics cd_cr_refund
       ON cr.cr_refunded_cdemo_sk = cd_cr_refund.cd_demo_sk
   LEFT JOIN household_demographics hd_cr_refund
       ON cr.cr_refunded_hdemo_sk = hd_cr_refund.hd_demo_sk
   LEFT JOIN store_sales ss
       ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN customer_address ca_ss
       ON ss.ss_addr_sk = ca_ss.ca_address_sk
   LEFT JOIN customer_demographics cd_ss
       ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
   LEFT JOIN household_demographics hd_ss
       ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
   LEFT JOIN web_sales ws
       ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN customer_address ca_ws_bill
       ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
   LEFT JOIN customer_demographics cd_ws_bill
       ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
   LEFT JOIN household_demographics hd_ws_bill
       ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
   LEFT JOIN customer_address ca_ws_ship
       ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
   LEFT JOIN customer_demographics cd_ws_ship
       ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
   LEFT JOIN household_demographics hd_ws_ship
       ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
   LEFT JOIN warehouse w_ws
       ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
)
SELECT
    cp_type,
    i_brand,
    w_warehouse_name,
    transaction_category,
    SUM(COALESCE(store_profit,0) + COALESCE(web_profit,0) - COALESCE(return_loss,0)) AS net_amount,
    COUNT(DISTINCT CASE WHEN transaction_category = 'store_sale' THEN ss_ticket_number END) AS distinct_store_sales,
    COUNT(DISTINCT CASE WHEN transaction_category = 'web_sale' THEN ws_order_number END) AS distinct_web_sales,
    COUNT(DISTINCT CASE WHEN transaction_category = 'return' THEN cr_order_number END) AS distinct_returns
FROM base
GROUP BY cp_type, i_brand, w_warehouse_name, transaction_category
ORDER BY net_amount DESC
LIMIT 100
