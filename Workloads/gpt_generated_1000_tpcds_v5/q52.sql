WITH sales_agg AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    ss.ss_store_sk,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(*) AS sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE i.i_category_id = 3
    AND ss.ss_store_sk IN (721, 532)
  GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, i.i_item_sk, i.i_product_name, i.i_category, ss.ss_store_sk
  HAVING SUM(ss.ss_net_paid) > 1000
)
SELECT
  sa.c_customer_sk,
  sa.c_first_name,
  sa.c_last_name,
  sa.i_product_name,
  sa.i_category,
  sa.ss_store_sk,
  sa.total_net_paid,
  sa.total_quantity,
  sa.sales_cnt,
  sa.sales_rank,
  inv.inv_quantity_on_hand,
  wp.wp_web_page_id,
  wp.wp_link_count,
  CASE WHEN wr.wr_return_quantity IS NULL THEN 0 ELSE wr.wr_return_quantity END AS return_quantity,
  SUM(wr.wr_return_amt) OVER (PARTITION BY sa.c_customer_sk ORDER BY wr.wr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt
FROM sales_agg sa
JOIN inventory inv ON inv.inv_item_sk = sa.i_item_sk
JOIN web_page wp ON wp.wp_customer_sk = sa.c_customer_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = sa.i_item_sk
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_link_count > 5
  AND inv.inv_quantity_on_hand >= 10
  AND wp.wp_rec_end_date > DATE '2000-01-01'
ORDER BY sa.total_net_paid DESC
LIMIT 100
