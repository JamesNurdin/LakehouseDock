WITH
  order_intersect AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
  ),
  catalog_agg AS (
    SELECT
      cs.cs_item_sk,
      ca.ca_state,
      w.w_state,
      SUM(cs.cs_net_paid) AS total_net_paid,
      CASE WHEN SUM(cs.cs_net_paid) > 50000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY CUBE (ca.ca_state, w.w_state, cs.cs_item_sk)
  ),
  reason_words AS (
    SELECT
      r.r_reason_sk,
      word
    FROM reason r
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
  )
SELECT
  ca_state,
  w_state,
  cs_item_sk,
  total_net_paid,
  sales_category,
  rw.word AS reason_word,
  NULL AS order_number
FROM catalog_agg ca
CROSS JOIN reason_words rw
WHERE NOT EXISTS (
  SELECT 1
  FROM store_returns sr
  WHERE sr.sr_item_sk = ca.cs_item_sk
)
UNION ALL
SELECT
  NULL AS ca_state,
  NULL AS w_state,
  NULL AS cs_item_sk,
  NULL AS total_net_paid,
  NULL AS sales_category,
  NULL AS reason_word,
  oi.order_number
FROM order_intersect oi
ORDER BY COALESCE(order_number, 0), ca_state
