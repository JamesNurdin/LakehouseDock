WITH sampled_sales AS (
  SELECT *
  FROM catalog_sales TABLESAMPLE BERNOULLI (5) -- sample 5% of rows
),
joined_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_profit,
    i.i_item_desc,
    i.i_category,
    p.p_promo_name,
    cc.cc_name,
    w.w_warehouse_name,
    regexp_extract(i.i_item_desc, '(?i)(shirt|pants)', 1) AS item_type,
    CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
  FROM sampled_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE regexp_like(i.i_item_desc, '(?i)shirt|pants')
    AND w.w_city LIKE 'A%'
),
order_without_returns AS (
  SELECT cs_order_number FROM sampled_sales
  EXCEPT
  SELECT cr_order_number FROM catalog_returns
),
union_agg AS (
  SELECT
    jd.cs_order_number AS order_number,
    jd.i_category AS category,
    jd.item_type,
    SUM(jd.cs_quantity) AS total_qty,
    SUM(jd.cs_net_profit) AS total_profit,
    jd.profit_flag
  FROM joined_data jd
  GROUP BY jd.cs_order_number, jd.i_category, jd.item_type, jd.profit_flag

  UNION

  SELECT
    cs.cs_order_number,
    i.i_category,
    regexp_extract(i.i_item_desc, '(?i)(shirt|pants)', 1) AS item_type,
    SUM(cs.cs_quantity) AS total_qty,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
  FROM sampled_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE i.i_item_desc LIKE '%shirt%' OR i.i_item_desc LIKE '%pants%'
  GROUP BY cs.cs_order_number, i.i_category, regexp_extract(i.i_item_desc, '(?i)(shirt|pants)', 1)
)
SELECT
  order_number,
  category,
  item_type,
  total_qty,
  total_profit,
  profit_flag,
  concat('ORD-', CAST(order_number AS varchar)) AS order_label
FROM union_agg
WHERE order_number IN (SELECT cs_order_number FROM order_without_returns)
ORDER BY total_profit DESC
OFFSET 20 LIMIT 100
