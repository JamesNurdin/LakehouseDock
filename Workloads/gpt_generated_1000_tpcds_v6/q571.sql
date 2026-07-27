WITH joined_data AS (
  SELECT
    cc.cc_name,
    w.w_warehouse_name,
    cs.cs_net_profit,
    ss.ss_net_profit,
    cr.cr_returned_date_sk,
    cs.cs_ext_list_price,
    cr.cr_reversed_charge,
    ss.ss_quantity
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
  JOIN store_sales ss ON ss.ss_addr_sk = ca_bill.ca_address_sk
  WHERE cc.cc_call_center_sk = 32
    AND w.w_zip = '56098'
    AND ca_bill.ca_state = 'CA'
    AND cr.cr_reversed_charge > 50
    AND cs.cs_ext_list_price > 2000
    AND ss.ss_quantity >= 2
),
agg_sales AS (
  SELECT
    cc_name,
    w_warehouse_name,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(ss_net_profit) AS total_store_profit,
    COUNT(cr_returned_date_sk) AS return_cnt,
    AVG(cs_ext_list_price) AS avg_list_price
  FROM joined_data
  GROUP BY cc_name, w_warehouse_name
)
SELECT
  cc_name,
  w_warehouse_name,
  total_catalog_profit,
  total_store_profit,
  return_cnt,
  avg_list_price,
  RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_catalog_profit DESC) AS profit_rank,
  total_catalog_profit / NULLIF(total_store_profit, 0) AS profit_ratio
FROM agg_sales
WHERE total_catalog_profit > 10000
ORDER BY total_catalog_profit DESC
LIMIT 100
