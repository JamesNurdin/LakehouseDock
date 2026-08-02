WITH
  item_inventory AS (
    SELECT
      i.i_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
      COUNT(DISTINCT inv.inv_warehouse_sk) AS distinct_warehouses
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_sk
  ),
  sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_category,
      i.i_current_price,
      s.s_store_name,
      cp.cp_department,
      sm.sm_carrier,
      ca_bill.ca_city AS bill_city,
      ca_ship.ca_city AS ship_city,
      SUM(ss.ss_quantity) AS total_quantity,
      SUM(ss.ss_sales_price) AS total_sales_price,
      SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
      COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amt,
      SUM(ss.ss_net_profit) AS total_net_profit,
      COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
      SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales_sum
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
                              AND sr.sr_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE ca_bill.ca_street_type = 'Avenue'
      AND ca_ship.ca_street_name IN ('Maple Spruce', 'Elm Wilson')
      AND sm.sm_carrier = 'UPS'
      AND i.i_current_price > 100
      AND w.w_state = 'CA'
    GROUP BY
      i.i_item_sk,
      i.i_product_name,
      i.i_category,
      i.i_current_price,
      s.s_store_name,
      cp.cp_department,
      sm.sm_carrier,
      ca_bill.ca_city,
      ca_ship.ca_city
  )
SELECT
  sa.i_item_sk,
  sa.i_product_name,
  sa.i_category,
  sa.i_current_price,
  sa.s_store_name,
  sa.cp_department,
  sa.sm_carrier,
  sa.bill_city,
  sa.ship_city,
  sa.total_quantity,
  sa.total_sales_price,
  sa.total_ext_sales_price,
  sa.total_return_amt,
  CASE WHEN sa.total_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
  sa.distinct_orders,
  sa.distinct_sales_sum,
  RANK() OVER (PARTITION BY sa.i_category ORDER BY sa.total_net_profit DESC) AS category_profit_rank,
  ii.total_quantity_on_hand,
  ii.distinct_warehouses,
  AVG(sa.total_quantity) OVER (PARTITION BY sa.i_category ORDER BY sa.total_quantity ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS moving_avg_quantity
FROM sales_agg sa
JOIN item_inventory ii ON ii.i_item_sk = sa.i_item_sk
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_sales cs2
  JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
  WHERE cs2.cs_item_sk = sa.i_item_sk
    AND cp2.cp_department = 'Office'
)
LIMIT 100
