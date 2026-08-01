WITH
  store_ret AS (
    SELECT i.i_item_sk AS item_sk,
           i.i_category AS category,
           i.i_brand AS brand,
           i.i_product_name AS product_name,
           t.t_hour AS hour_of_day,
           sr.sr_return_amt_inc_tax AS return_amount,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  ),
  catalog_ret AS (
    SELECT i.i_item_sk AS item_sk,
           i.i_category AS category,
           i.i_brand AS brand,
           i.i_product_name AS product_name,
           t.t_hour AS hour_of_day,
           cr.cr_return_amt_inc_tax AS return_amount,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  ),
  web_ret AS (
    SELECT i.i_item_sk AS item_sk,
           i.i_category AS category,
           i.i_brand AS brand,
           i.i_product_name AS product_name,
           t.t_hour AS hour_of_day,
           wr.wr_return_amt_inc_tax AS return_amount,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
  ),
  all_ret AS (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
  ),
  filtered_ret AS (
    SELECT *
    FROM all_ret
    WHERE regexp_like(product_name, '^Super[0-9]{3}$')
      AND product_name LIKE '%Deluxe%'
  ),
  aggregated_ret AS (
    SELECT
      category,
      brand,
      product_name,
      SUM(return_amount) AS total_return_amount,
      SUM(net_loss) AS total_net_loss,
      COUNT(*) AS return_count,
      CONCAT(category, ' - ', brand) AS category_brand,
      regexp_extract(product_name, '\\d+', 0) AS product_code
    FROM filtered_ret
    GROUP BY
      category,
      brand,
      product_name,
      CONCAT(category, ' - ', brand),
      regexp_extract(product_name, '\\d+', 0)
  )
SELECT
  category,
  brand,
  product_name,
  total_return_amount,
  total_net_loss,
  return_count,
  category_brand,
  product_code,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_return_amount DESC) AS rank_in_category
FROM aggregated_ret
ORDER BY total_return_amount DESC
LIMIT 100
