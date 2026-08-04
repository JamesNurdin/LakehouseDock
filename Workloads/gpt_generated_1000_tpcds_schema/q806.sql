WITH
  cs_sample AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 5
      AND cs_net_paid > 100
      AND cs_ship_mode_sk IS NOT NULL
      AND cs_warehouse_sk IN (10, 11, 16, 19, 20)
      AND cs_sold_date_sk BETWEEN 2450836 AND 2451074
  ),
  ws_sample AS (
    SELECT *
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_quantity > 5
      AND ws_net_paid > 100
      AND ws_ship_mode_sk IS NOT NULL
      AND ws_warehouse_sk IN (10, 11, 16, 19, 20)
      AND ws_sold_date_sk BETWEEN 2450836 AND 2451074
  ),
  cs_customers_except_ws AS (
    SELECT cs_bill_customer_sk AS cust_sk
    FROM tpcds.catalog_sales
    EXCEPT
    SELECT ws_bill_customer_sk FROM tpcds.web_sales
  ),
  intersect_items AS (
    SELECT cs_item_sk AS item_sk
    FROM tpcds.catalog_sales
    INTERSECT
    SELECT ws_item_sk FROM tpcds.web_sales
  ),
  cs_join AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      i.i_item_sk,
      i.i_product_name,
      w.w_warehouse_name,
      sm.sm_ship_mode_id,
      cc.cc_name AS call_center_name,
      p.p_promo_name,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      inv.inv_quantity_on_hand,
      (cs.cs_net_paid * cs.cs_quantity) AS total_sales
    FROM cs_sample cs
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.inventory inv
      ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_bill_customer_sk IN (SELECT cust_sk FROM cs_customers_except_ws)
      AND i.i_item_sk IN (SELECT item_sk FROM intersect_items)
      AND ca.ca_state = 'CA'
      AND w.w_state = 'CA'
      AND sm.sm_carrier = 'DHL'
  ),
  ws_join AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      i.i_item_sk,
      i.i_product_name,
      w.w_warehouse_name,
      sm.sm_ship_mode_id,
      NULL AS call_center_name,
      p.p_promo_name,
      ws.ws_quantity AS cs_quantity,
      ws.ws_net_paid AS cs_net_paid,
      ws.ws_net_profit AS cs_net_profit,
      inv.inv_quantity_on_hand,
      (ws.ws_net_paid * ws.ws_quantity) AS total_sales
    FROM ws_sample ws
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.inventory inv
      ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_item_sk IN (SELECT item_sk FROM intersect_items)
      AND ca.ca_state = 'CA'
      AND w.w_state = 'CA'
      AND sm.sm_carrier = 'DHL'
  ),
  combined AS (
    SELECT * FROM cs_join
    UNION ALL
    SELECT * FROM ws_join
  )
SELECT
  c_customer_sk,
  c_first_name,
  c_last_name,
  ca_city,
  i_product_name,
  w_warehouse_name,
  sm_ship_mode_id,
  call_center_name,
  p_promo_name,
  cs_quantity,
  cs_net_paid,
  cs_net_profit,
  total_sales,
  CASE WHEN cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  (SELECT SUM(inv_quantity_on_hand)
   FROM tpcds.inventory inv2
   WHERE inv2.inv_item_sk = combined.i_item_sk) AS total_inventory_for_item,
  ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS product_rank_in_warehouse
FROM combined
ORDER BY total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
