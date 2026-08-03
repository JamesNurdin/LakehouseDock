WITH
  intersect_items AS (
    SELECT cs_item_sk FROM catalog_sales
    INTERSECT
    SELECT inv_item_sk FROM inventory
  ),

  inv_w AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      w.w_warehouse_sk,
      w.w_state
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN warehouse w_dup ON inv.inv_warehouse_sk = w_dup.w_warehouse_sk
  ),

  sales AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_call_center_sk,
      cs.cs_warehouse_sk,
      cs.cs_item_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cc.cc_name,
      cc.cc_division,
      w.w_state,
      ca_bill.ca_state        AS bill_state,
      ca_ship.ca_state        AS ship_state,
      s.s_store_name,
      sr.sr_return_amt_inc_tax,
      sr.sr_store_credit,
      iw.w_state               AS inv_warehouse_state
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN call_center cc2 ON cs.cs_call_center_sk = cc2.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN store_returns sr ON sr.sr_addr_sk = ca_bill.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
    JOIN intersect_items ii ON cs.cs_item_sk = ii.cs_item_sk
    JOIN inv_w iw ON cs.cs_warehouse_sk = iw.w_warehouse_sk
    WHERE cs.cs_item_sk IN (
      SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0
    )
  ),

  exploded AS (
    SELECT
      s.*, 
      t.letter
    FROM sales s
    LEFT JOIN UNNEST(split(s.cc_name, '')) AS t(letter) ON true
  ),

  aggregated AS (
    SELECT
      e.cc_name,
      e.w_state,
      e.bill_state,
      SUM(e.cs_net_paid)               AS total_net_paid,
      SUM(e.cs_net_profit)            AS total_net_profit,
      SUM(e.sr_return_amt_inc_tax)    AS total_return_amount,
      COUNT(DISTINCT e.cs_sold_date_sk) AS distinct_sale_days,
      e.letter
    FROM exploded e
    GROUP BY e.cc_name, e.w_state, e.bill_state, e.letter
  )
SELECT
  a.cc_name,
  a.w_state,
  a.bill_state,
  a.total_net_paid,
  a.total_net_profit,
  a.total_return_amount,
  a.distinct_sale_days,
  SUM(a.total_net_paid) OVER (
    PARTITION BY a.cc_name
    ORDER BY a.total_net_paid DESC
    ROWS UNBOUNDED PRECEDING
  )                                   AS running_total_net_paid,
  a.letter
FROM aggregated a
WHERE a.total_net_paid > 5000
ORDER BY a.total_net_paid DESC
LIMIT 100
