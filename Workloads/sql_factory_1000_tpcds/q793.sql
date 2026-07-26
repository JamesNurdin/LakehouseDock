WITH combined_sales AS (
  SELECT cs_bill_customer_sk AS customer_sk,
         cs_item_sk AS item_sk,
         cs_quantity AS quantity,
         cs_sold_date_sk AS date_sk
  FROM catalog_sales
  UNION ALL
  SELECT ws_bill_customer_sk AS customer_sk,
         ws_item_sk AS item_sk,
         ws_quantity AS quantity,
         ws_sold_date_sk AS date_sk
  FROM web_sales
),
monthly_qty AS (
  SELECT cs.customer_sk,
         d.d_year AS year,
         d.d_month_seq AS month_seq,
         SUM(cs.quantity) AS total_quantity
  FROM combined_sales cs
  JOIN date_dim d ON d.d_date_sk = cs.date_sk
  GROUP BY cs.customer_sk, d.d_year, d.d_month_seq
),
ordered_qty AS (
  SELECT customer_sk,
         year,
         month_seq,
         total_quantity,
         LAG(total_quantity, 1) OVER (PARTITION BY customer_sk ORDER BY year, month_seq) AS qty_lag1,
         LAG(total_quantity, 2) OVER (PARTITION BY customer_sk ORDER BY year, month_seq) AS qty_lag2
  FROM monthly_qty
),
increasing_customers AS (
  SELECT customer_sk,
         year,
         month_seq,
         total_quantity,
         CASE WHEN qty_lag1 IS NOT NULL AND qty_lag2 IS NOT NULL AND total_quantity > qty_lag1 AND qty_lag1 > qty_lag2 THEN 1 ELSE 0 END AS is_increasing
  FROM ordered_qty
),
customer_item_agg AS (
  SELECT cs.customer_sk,
         i.i_brand,
         i.i_category,
         SUM(cs.quantity) AS total_quantity
  FROM combined_sales cs
  JOIN item i ON i.i_item_sk = cs.item_sk
  GROUP BY cs.customer_sk, i.i_brand, i.i_category
),
customer_top_item AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_quantity DESC) AS rn
  FROM customer_item_agg
),
customer_summary AS (
  SELECT ic.customer_sk,
         MAX(ic.year) AS latest_year,
         MAX(ic.month_seq) AS latest_month_seq,
         MAX(ic.total_quantity) AS latest_total_quantity,
         MAX(ic.is_increasing) AS is_increasing_flag,
         ti.i_brand AS top_brand,
         ti.i_category AS top_category
  FROM increasing_customers ic
  JOIN customer_top_item ti ON ti.customer_sk = ic.customer_sk AND ti.rn = 1
  GROUP BY ic.customer_sk, ti.i_brand, ti.i_category
  HAVING MAX(ic.is_increasing) = 1
)
SELECT
  cs.customer_sk,
  cs.latest_year,
  cs.latest_month_seq,
  cs.latest_total_quantity,
  RANK() OVER (ORDER BY cs.latest_total_quantity DESC) AS quantity_rank,
  'Increasing' AS trend_status,
  cs.top_brand,
  cs.top_category
FROM customer_summary cs
ORDER BY quantity_rank
LIMIT 20
