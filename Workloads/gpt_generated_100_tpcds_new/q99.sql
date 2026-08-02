WITH inv_agg AS (
   SELECT
       inv_date_sk,
       inv_item_sk,
       inv_warehouse_sk,
       SUM(inv_quantity_on_hand) AS total_quantity_on_hand
   FROM inventory TABLESAMPLE BERNOULLI (10)
   GROUP BY inv_date_sk, inv_item_sk, inv_warehouse_sk
)

SELECT
   store.s_store_id,
   store.s_city,
   d_sold.d_year,
   cs.cs_net_paid,
   cs.cs_net_profit,
   inv_agg.total_quantity_on_hand,
   CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
   RANK() OVER (PARTITION BY store.s_store_id ORDER BY cs.cs_net_paid DESC) AS sales_rank
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer cu
  ON cs.cs_bill_customer_sk = cu.c_customer_sk
JOIN web_page wp
  ON wp.wp_customer_sk = cu.c_customer_sk
  AND wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = cu.c_customer_sk
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store
  ON sr.sr_store_sk = store.s_store_sk
JOIN reason
  ON sr.sr_reason_sk = reason.r_reason_sk
JOIN inv_agg
  ON inv_agg.inv_date_sk = d_return.d_date_sk
WHERE d_sold.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  AND cc.cc_city = 'Glendale'
  AND inv_agg.inv_warehouse_sk IN (1, 2, 3)
  AND store.s_state = 'CA'
  AND reason.r_reason_desc LIKE '%defect%'

UNION DISTINCT

SELECT
   store.s_store_id,
   store.s_city,
   d_sold.d_year,
   cs.cs_net_paid,
   cs.cs_net_profit,
   inv_agg.total_quantity_on_hand,
   CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
   ROW_NUMBER() OVER (PARTITION BY store.s_store_id ORDER BY cs.cs_net_paid ASC) AS sales_rank
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer cu
  ON cs.cs_bill_customer_sk = cu.c_customer_sk
JOIN web_page wp
  ON wp.wp_customer_sk = cu.c_customer_sk
  AND wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = cu.c_customer_sk
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store
  ON sr.sr_store_sk = store.s_store_sk
JOIN reason
  ON sr.sr_reason_sk = reason.r_reason_sk
JOIN inv_agg
  ON inv_agg.inv_date_sk = d_return.d_date_sk
WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND cc.cc_city = 'Antioch'
  AND inv_agg.inv_warehouse_sk = 5
  AND store.s_state = 'TX'
  AND reason.r_reason_desc LIKE '%customer%'

ORDER BY sales_rank
LIMIT 100
