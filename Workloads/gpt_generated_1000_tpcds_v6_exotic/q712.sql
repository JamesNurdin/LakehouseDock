WITH filtered_items AS (
  SELECT DISTINCT inv.inv_item_sk
  FROM tpcds.inventory inv
  WHERE inv.inv_quantity_on_hand > 0
),
item_sales AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_ticket_number,
    ss.ss_item_sk,
    ss.ss_addr_sk,
    ss.ss_store_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    i.i_item_id,
    i.i_product_name,
    i.i_units,
    i.i_category,
    i.i_brand,
    ca.ca_state,
    ca.ca_city,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand
  FROM tpcds.store_sales ss
  JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.inventory inv
    ON i.i_item_sk = inv.inv_item_sk
  WHERE i.i_units = 'Carton'
    AND ca.ca_state = 'CA'
    AND inv.inv_warehouse_sk IN (3, 9, 15)
    AND EXISTS (
      SELECT 1
      FROM filtered_items fi
      WHERE fi.inv_item_sk = ss.ss_item_sk
    )
)
SELECT
  ca_state,
  i_category,
  i_brand,
  inv_warehouse_sk,
  SUM(ss_quantity) AS total_quantity,
  SUM(ss_net_profit) AS total_profit,
  RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ss_net_profit) DESC) AS profit_rank_state,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(ss_quantity) DESC) AS qty_rownum_category,
  CASE
    WHEN SUM(ss_net_profit) > (SELECT AVG(ss_net_profit) FROM tpcds.store_sales) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS profit_vs_avg
FROM item_sales
GROUP BY
  ca_state,
  i_category,
  i_brand,
  inv_warehouse_sk
ORDER BY total_profit DESC
LIMIT 100
