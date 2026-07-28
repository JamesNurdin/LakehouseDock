WITH cs AS (
   SELECT
      cs.cs_order_number,
      cs.cs_bill_addr_sk,
      cs.cs_ship_addr_sk,
      cs.cs_ship_customer_sk,
      cs.cs_ext_wholesale_cost,
      cs.cs_ext_list_price,
      cs.cs_net_profit
   FROM catalog_sales cs
   WHERE cs.cs_ext_wholesale_cost > 2000
     AND cs.cs_ext_list_price BETWEEN 3000 AND 20000
     AND cs.cs_ship_customer_sk IN (3116427, 4936748, 141731)
),

ca AS (
   SELECT
      ca.ca_address_sk,
      ca.ca_state,
      ca.ca_gmt_offset,
      ca.ca_street_name
   FROM customer_address ca
   WHERE ca.ca_state IN ('CA', 'TX', 'NY')
     AND ca.ca_gmt_offset BETWEEN -10.00 AND -6.00
)

SELECT
   cs.cs_order_number,
   ca.ca_state,
   ca.ca_street_name,
   cs.cs_ext_wholesale_cost,
   cs.cs_ext_list_price,
   cs.cs_net_profit,
   wr.wr_fee,
   wr.wr_net_loss,
   CASE
      WHEN wr.wr_net_loss > 1000 THEN 'High Loss'
      WHEN wr.wr_net_loss > 500 THEN 'Medium Loss'
      ELSE 'Low Loss'
   END AS loss_category,
   ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY wr.wr_net_loss DESC NULLS LAST) AS rn_state_loss,
   RANK() OVER (ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM cs
LEFT JOIN ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN web_returns wr
   ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE wr.wr_fee > 30
  AND wr.wr_return_quantity > 0
  AND wr.wr_net_loss IS NOT NULL
  AND (ca.ca_street_name LIKE '%Hill%' OR ca.ca_street_name LIKE '%Pine%')
ORDER BY profit_rank
LIMIT 100
