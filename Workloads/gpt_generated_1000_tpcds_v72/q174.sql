WITH
  catalog AS (
    SELECT
      i.i_item_id,
      i.i_brand,
      SUM(cs.cs_ext_sales_price) AS sales_amount,
      'catalog' AS channel
    FROM
      catalog_sales cs
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE
      t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_return_quantity > 0
      )
    GROUP BY
      i.i_item_id,
      i.i_brand
  ),
  web AS (
    SELECT
      i.i_item_id,
      i.i_brand,
      SUM(ws.ws_ext_sales_price) AS sales_amount,
      'web' AS channel
    FROM
      web_sales ws
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE
      t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_quantity > 0
      )
    GROUP BY
      i.i_item_id,
      i.i_brand
  ),
  combined AS (
    SELECT i_item_id, i_brand, sales_amount, channel FROM catalog
    UNION ALL
    SELECT i_item_id, i_brand, sales_amount, channel FROM web
  )
SELECT
  i_item_id,
  i_brand,
  sales_amount,
  channel
FROM
  combined
ORDER BY
  sales_amount DESC
LIMIT 100
