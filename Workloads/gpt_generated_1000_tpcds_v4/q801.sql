WITH base_data AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_color,
    i.i_container,
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_ext_list_price,
    ss.ss_net_profit,
    sr.sr_return_quantity,
    sr.sr_fee,
    sr.sr_store_sk
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
  WHERE ss.ss_ext_list_price > 1000
    AND ss.ss_net_profit < 0
    AND sr.sr_fee > 30
    AND sr.sr_store_sk IN (500, 733, 304)
    AND i.i_color IN ('purple', 'turquoise')
    AND i.i_container = 'Unknown'
),

sales_rank AS (
  SELECT
    i_item_id,
    i_product_name,
    SUM(ss_ext_list_price) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_ext_list_price) DESC) AS sales_rank
  FROM base_data
  GROUP BY i_item_id, i_product_name
  HAVING SUM(ss_ext_list_price) > 2000
),

return_rank AS (
  SELECT
    i_item_id,
    i_product_name,
    SUM(sr_fee) AS total_return_fee,
    ROW_NUMBER() OVER (ORDER BY SUM(sr_fee) DESC) AS return_rank
  FROM base_data
  GROUP BY i_item_id, i_product_name
  HAVING SUM(sr_fee) > 100
),

top_sales AS (
  SELECT
    i_item_id,
    i_product_name,
    total_sales,
    sales_rank,
    NULL AS total_return_fee,
    NULL AS return_rank
  FROM sales_rank
  WHERE sales_rank <= 5
),

top_returns AS (
  SELECT
    i_item_id,
    i_product_name,
    NULL AS total_sales,
    NULL AS sales_rank,
    total_return_fee,
    return_rank
  FROM return_rank
  WHERE return_rank <= 5
),

combined AS (
  SELECT * FROM top_sales
  UNION ALL
  SELECT * FROM top_returns
)

SELECT
  i_item_id,
  i_product_name,
  total_sales,
  sales_rank,
  total_return_fee,
  return_rank,
  AVG(total_sales) OVER (
    ORDER BY sales_rank
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ) AS mov_avg_sales
FROM combined
ORDER BY COALESCE(sales_rank, return_rank) ASC, i_item_id
