WITH sampled_catalog AS (
  SELECT cs.*
  FROM catalog_sales cs
  TABLESAMPLE BERNOULLI (10)
  WHERE cs.cs_sales_price > 10
    AND cs.cs_quantity >= 2
    AND cs.cs_ship_customer_sk BETWEEN 1000000 AND 5000000
    AND cs.cs_list_price < 200
),
item_inventory AS (
  SELECT i.i_item_sk,
         i.i_category,
         i.i_formulation,
         inv.inv_quantity_on_hand
  FROM item i
  FULL OUTER JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
)
SELECT
  sub.hd_dep_count,
  sub.i_category,
  AVG(sub.group_sales) AS avg_sales_per_category,
  COUNT(DISTINCT u.form_part) AS distinct_form_parts
FROM (
  SELECT
    hd.hd_dep_count,
    ii.i_category,
    ii.i_formulation,
    SUM(cs.cs_ext_sales_price) AS group_sales
  FROM sampled_catalog cs
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item_inventory ii
    ON cs.cs_item_sk = ii.i_item_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = ii.i_item_sk
  WHERE ws.ws_ext_list_price > 1000
    AND ws.ws_net_paid_inc_tax < 2000
    AND ws.ws_ship_customer_sk BETWEEN 1000000 AND 9000000
    AND ws.ws_quantity >= 1
  GROUP BY hd.hd_dep_count, ii.i_category, ii.i_formulation
) sub
LEFT JOIN LATERAL (
  SELECT form_part
  FROM UNNEST(split(sub.i_formulation, '')) AS t(form_part)
) AS u ON true
GROUP BY sub.hd_dep_count, sub.i_category
HAVING AVG(sub.group_sales) > 500
ORDER BY avg_sales_per_category DESC
LIMIT 100
