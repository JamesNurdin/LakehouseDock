WITH
  returns_agg AS (
    SELECT
      i.i_category_id,
      i.i_brand_id,
      t_ret.t_hour,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    WHERE cr.cr_returning_customer_sk IN (8836584, 2297938, 4141161)
      AND cr.cr_reversed_charge > 10
      AND i.i_current_price BETWEEN 1 AND 100
      AND t_ret.t_minute IN (3, 15, 16)
      AND cr.cr_return_quantity >= 1
    GROUP BY GROUPING SETS (
      (i.i_category_id, i.i_brand_id, t_ret.t_hour),
      (i.i_category_id, i.i_brand_id),
      (i.i_category_id),
      ()
    )
  ),
  sales_agg AS (
    SELECT
      i.i_category_id,
      i.i_brand_id,
      SUM(ws.ws_ext_sales_price) AS total_sales_amount,
      SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t_sale ON ws.ws_sold_time_sk = t_sale.t_time_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450880 AND 2451000
      AND ws.ws_quantity > 0
      AND ws.ws_ext_discount_amt < 50
      AND i.i_category_id IN (2, 4, 5, 7, 9)
      AND t_sale.t_minute >= 10
    GROUP BY i.i_category_id, i.i_brand_id
  )
SELECT
  r.i_category_id,
  r.i_brand_id,
  r.t_hour,
  r.total_return_amount,
  s.total_sales_amount,
  r.return_cnt,
  s.total_quantity,
  CASE
    WHEN s.total_sales_amount IS NULL OR s.total_sales_amount = 0 THEN NULL
    ELSE r.total_return_amount / s.total_sales_amount
  END AS return_to_sales_ratio,
  RANK() OVER (ORDER BY r.total_return_amount DESC) AS return_amount_rank
FROM returns_agg r
LEFT JOIN sales_agg s
  ON r.i_category_id = s.i_category_id
 AND r.i_brand_id = s.i_brand_id
ORDER BY return_amount_rank
LIMIT 100
