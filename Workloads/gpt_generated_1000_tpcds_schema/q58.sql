WITH scalar_price AS (
    SELECT i_category, AVG(i_current_price) AS avg_price_by_cat
    FROM tpcds.item
    GROUP BY i_category
)
SELECT
    i.i_item_id,
    p.p_promo_name,
    d_ss.d_year,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT w_ws.w_warehouse_name) AS distinct_warehouses,
    cc.cc_name
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN tpcds.item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.household_demographics hd_ss
  ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN tpcds.income_band ib_ss
  ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
JOIN tpcds.customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN tpcds.call_center cc
  ON cc.cc_open_date_sk = d_ss.d_date_sk
-- inventory related joins (different aliases)
JOIN tpcds.inventory inv
  ON i.i_item_sk = inv.inv_item_sk
JOIN tpcds.date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN tpcds.warehouse w_inv
  ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
-- web_sales and its dimensions
JOIN tpcds.web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
JOIN tpcds.date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN tpcds.date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN tpcds.household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.income_band ib_bill
  ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN tpcds.customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN tpcds.date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN tpcds.warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN tpcds.promotion p_ws
  ON ws.ws_promo_sk = p_ws.p_promo_sk
WHERE d_ss.d_year = 2002
  AND i.i_current_price > (
        SELECT avg_price_by_cat
        FROM scalar_price sp
        WHERE sp.i_category = i.i_category
    )
GROUP BY
    i.i_item_id,
    p.p_promo_name,
    d_ss.d_year,
    cc.cc_name
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY store_net_profit DESC
LIMIT 100
