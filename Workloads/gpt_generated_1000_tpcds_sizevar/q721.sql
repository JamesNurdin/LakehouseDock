WITH sales_filtered AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_ticket_number,
    ss.ss_store_sk,
    ss.ss_item_sk,
    ss.ss_net_profit,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    i.i_brand,
    i.i_product_name,
    i.i_item_desc,
    s.s_store_id,
    s.s_store_name,
    d.d_date
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND i.i_product_name LIKE '%ABC%'
    AND REGEXP_LIKE(i.i_product_name, '[0-9]{2}')
    AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_net_loss > 0
    )
),

agg_sales AS (
  SELECT
    s_store_id,
    s_store_name,
    i_brand,
    i_product_name,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_quantity) AS total_quantity,
    AVG(ss_ext_sales_price) AS avg_price
  FROM sales_filtered
  GROUP BY s_store_id, s_store_name, i_brand, i_product_name
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_profit DESC) AS rank_per_store
  FROM agg_sales
)
SELECT
  s_store_id,
  s_store_name,
  CONCAT(i_brand, ' ', i_product_name) AS product_full_name,
  REGEXP_EXTRACT(i_product_name, '(\\d+)', 1) AS extracted_number,
  CASE WHEN REGEXP_LIKE(i_product_name, '[0-9]{2}') THEN 'has_two_digits' ELSE 'no_two_digits' END AS digit_flag,
  total_profit,
  total_quantity,
  avg_price,
  CASE
    WHEN total_profit > 10000 THEN 'high'
    WHEN total_profit > 0 THEN 'medium'
    ELSE 'low'
  END AS profit_category,
  rank_per_store
FROM ranked
WHERE rank_per_store <= 5
ORDER BY s_store_id, rank_per_store
LIMIT 100
