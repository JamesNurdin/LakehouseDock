WITH sales_detail AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_product_name,
        i.i_brand,
        w.w_warehouse_name,
        p.p_promo_name,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        s.web_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE ws.ws_ext_sales_price > 1000
      AND ws.ws_net_profit > 0
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = ws.ws_item_sk
            AND inv.inv_quantity_on_hand > 500
      )
)
SELECT
    d.web_name,
    d.i_product_name,
    d.c_first_name,
    d.c_last_name,
    d.w_warehouse_name,
    d.p_promo_name,
    d.ws_quantity,
    d.ws_ext_sales_price,
    d.ws_net_profit,
    ROW_NUMBER() OVER (PARTITION BY d.ws_web_site_sk ORDER BY d.ws_net_profit DESC) AS profit_rank
FROM sales_detail d
ORDER BY d.ws_net_profit DESC
LIMIT 100
