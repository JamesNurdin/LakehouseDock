WITH anti AS (
   SELECT cs_order_number
   FROM catalog_sales
   WHERE cs_net_profit < 0
),
intersect_keys AS (
   SELECT cs_order_number FROM catalog_sales WHERE cs_quantity = 10
   INTERSECT
   SELECT cs_order_number FROM catalog_sales WHERE cs_ext_sales_price > 500
),
except_keys AS (
   SELECT cs_order_number FROM catalog_sales WHERE cs_quantity >= 1
   EXCEPT
   SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 100
)
SELECT
   ca.ca_state,
   cd.cd_gender,
   d.d_year,
   i.i_category,
   sm.sm_type,
   SUM(cs.cs_ext_sales_price) AS total_sales,
   AVG(cs.cs_quantity)        AS avg_qty,
   COUNT(*)                   AS order_cnt,
   MIN(cs.cs_net_profit)      AS min_profit,
   MAX(cs.cs_net_profit)      AS max_profit
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND i.i_category = 'Books'
  AND sm.sm_type = 'AIR'
  AND cs.cs_quantity > 5
  AND cs.cs_ext_sales_price > 100.00
  AND inv.inv_quantity_on_hand > 200
  AND cs.cs_order_number NOT IN (SELECT cs_order_number FROM anti)
  AND cs.cs_order_number IN (SELECT cs_order_number FROM intersect_keys)
  AND cs.cs_order_number NOT IN (SELECT cs_order_number FROM except_keys)
GROUP BY CUBE (ca.ca_state, cd.cd_gender, d.d_year, i.i_category, sm.sm_type)
ORDER BY total_sales DESC
LIMIT 100
