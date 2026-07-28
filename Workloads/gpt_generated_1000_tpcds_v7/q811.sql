WITH catalog_part AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    cs.cs_net_paid,
    cs.cs_net_profit,
    ca.ca_state
  FROM tpcds.catalog_sales cs
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE p.p_purpose = 'Unknown'
    AND ca.ca_state = 'CO'
),
store_part AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ca.ca_state
  FROM tpcds.store_sales ss
  JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE p.p_purpose = 'Unknown'
    AND ca.ca_state = 'CO'
)
SELECT
  item_id,
  product_name,
  SUM(net_paid) AS total_net_paid,
  SUM(net_profit) AS total_net_profit,
  COUNT(*) AS transaction_count
FROM (
  SELECT
    i_item_id AS item_id,
    i_product_name AS product_name,
    cs_net_paid AS net_paid,
    cs_net_profit AS net_profit,
    ca_state
  FROM catalog_part
  UNION ALL
  SELECT
    i_item_id AS item_id,
    i_product_name AS product_name,
    ss_net_paid AS net_paid,
    ss_net_profit AS net_profit,
    ca_state
  FROM store_part
) AS combined
GROUP BY item_id, product_name
ORDER BY total_net_profit DESC
LIMIT 20
