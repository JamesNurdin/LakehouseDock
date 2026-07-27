WITH base AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        sr.sr_net_loss,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        i.i_brand,
        wh_cs.w_city,
        cd_bill.cd_gender,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse wh_cs
        ON cs.cs_warehouse_sk = wh_cs.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = wh_cs.w_warehouse_sk
    JOIN warehouse wh_inv
        ON wh_cs.w_warehouse_sk = wh_inv.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer cust_page
        ON wp.wp_customer_sk = cust_page.c_customer_sk
)
SELECT
    wh_cs.w_city AS warehouse_city,
    i.i_brand AS brand,
    cd_bill.cd_gender AS customer_gender,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty
FROM catalog_sales cs
JOIN customer cust_bill            ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk   = cd_bill.cd_demo_sk
JOIN customer_address ca_bill      ON cs.cs_bill_addr_sk    = ca_bill.ca_address_sk
JOIN customer cust_ship            ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk   = cd_ship.cd_demo_sk
JOIN customer_address ca_ship      ON cs.cs_ship_addr_sk    = ca_ship.ca_address_sk
JOIN warehouse wh_cs               ON cs.cs_warehouse_sk    = wh_cs.w_warehouse_sk
JOIN item i                        ON cs.cs_item_sk         = i.i_item_sk
LEFT JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = wh_cs.w_warehouse_sk
JOIN warehouse wh_inv              ON wh_cs.w_warehouse_sk = wh_inv.w_warehouse_sk
JOIN store_returns sr              ON sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_sr   ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr        ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_sales ws                  ON ws.ws_item_sk = i.i_item_sk
                                 AND ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN web_page wp                   ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit                 ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN customer cust_page            ON wp.wp_customer_sk = cust_page.c_customer_sk
GROUP BY
    wh_cs.w_city,
    i.i_brand,
    cd_bill.cd_gender
HAVING
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) > 10000
ORDER BY
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) DESC
LIMIT 100
