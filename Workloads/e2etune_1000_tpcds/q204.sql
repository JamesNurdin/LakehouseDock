WITH item_sales AS (
  SELECT
    ss.ss_item_sk,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_coupon_amt) AS avg_coupon
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    AND ss.ss_quantity > 0
  GROUP BY ss.ss_item_sk
),
category_totals AS (
  SELECT
    i.i_category,
    SUM(s.total_profit) AS cat_total_profit
  FROM item i
  JOIN item_sales s ON i.i_item_sk = s.ss_item_sk
  GROUP BY i.i_category
)
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  i.i_class,
  i.i_units,
  s.total_quantity,
  s.total_sales,
  s.total_profit,
  s.avg_coupon,
  ROUND(s.total_profit / NULLIF(s.total_sales, 0), 4) AS profit_margin,
  ROUND(s.total_profit / NULLIF(ct.cat_total_profit, 0), 4) AS profit_share_of_category,
  RANK() OVER (PARTITION BY i.i_category ORDER BY s.total_profit DESC) AS profit_rank_in_category
FROM item i
JOIN item_sales s ON i.i_item_sk = s.ss_item_sk
JOIN category_totals ct ON i.i_category = ct.i_category
WHERE i.i_category_id IN (1, 3, 5)
  AND i.i_units = 'Bundle'
ORDER BY i.i_category, profit_rank_in_category
LIMIT 20
