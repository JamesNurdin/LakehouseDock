WITH inventory_agg AS (
  SELECT inv_item_sk,
         SUM(inv_quantity_on_hand) AS total_on_hand
  FROM inventory
  WHERE inv_quantity_on_hand > 0
    AND inv_warehouse_sk IN (1, 2)
  GROUP BY inv_item_sk
),
sales_agg AS (
  SELECT ss_item_sk,
         SUM(ss_ext_sales_price) AS total_sales,
         SUM(ss_net_profit) AS total_profit,
         COUNT(*) AS sales_cnt
  FROM store_sales
  WHERE ss_quantity > 0
    AND ss_sales_price > 20
    AND ss_ext_tax > 0
    AND ss_sold_date_sk BETWEEN 2451910 AND 2451950
  GROUP BY ss_item_sk
),
returns_agg AS (
  SELECT cr_item_sk,
         SUM(cr_return_amount) AS total_return_amount,
         SUM(cr_return_quantity) AS total_return_qty
  FROM catalog_returns
  WHERE cr_return_amount > 0
    AND cr_return_quantity > 0
    AND cr_reason_sk IS NOT NULL
  GROUP BY cr_item_sk
),
sales_customer AS (
  SELECT ss_item_sk,
         MIN(ss_addr_sk) AS addr_sk,
         MIN(ss_cdemo_sk) AS cdemo_sk
  FROM store_sales
  GROUP BY ss_item_sk
)
SELECT
  i.i_item_sk,
  i.i_product_name,
  i.i_wholesale_cost,
  i.i_manager_id,
  i.i_brand,
  inv.total_on_hand,
  s.total_sales,
  s.total_profit,
  r.total_return_amount,
  r.total_return_qty,
  ca.ca_city,
  cd.cd_gender,
  p.p_promo_name
FROM sales_agg s
JOIN item i
  ON s.ss_item_sk = i.i_item_sk
JOIN inventory_agg inv
  ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN returns_agg r
  ON i.i_item_sk = r.cr_item_sk
JOIN sales_customer sc
  ON i.i_item_sk = sc.ss_item_sk
JOIN customer_address ca
  ON sc.addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON sc.cdemo_sk = cd.cd_demo_sk
LEFT JOIN promotion p
  ON i.i_item_sk = p.p_item_sk
WHERE i.i_wholesale_cost BETWEEN 5 AND 50
  AND i.i_manager_id IN (21, 34)
  AND ca.ca_gmt_offset = -7.00
  AND cd.cd_gender = 'F'
ORDER BY s.total_sales DESC
LIMIT 100
