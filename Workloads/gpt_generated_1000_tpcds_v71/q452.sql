WITH
  catalog_sales_returns AS (
    SELECT
      cs.cs_sold_date_sk AS date_sk,
      i.i_item_id,
      i.i_category,
      cs.cs_net_paid AS net_paid,
      cr.cr_return_amount AS return_amount,
      cs.cs_order_number,
      ROW_NUMBER() OVER (PARTITION BY cs.cs_sold_date_sk, i.i_item_id ORDER BY cs.cs_net_paid DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
    WHERE i.i_size = 'large'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451543
  ),
  web_sales_returns AS (
    SELECT
      ws.ws_sold_date_sk AS date_sk,
      i.i_item_id,
      i.i_category,
      ws.ws_net_paid AS net_paid,
      wr.wr_return_amt AS return_amount,
      ws.ws_order_number,
      ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk, i.i_item_id ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
    WHERE i.i_color = 'red'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451543
  )
SELECT
  date_sk,
  i_item_id,
  i_category,
  net_paid,
  return_amount,
  sales_rank,
  'catalog' AS channel
FROM catalog_sales_returns

UNION ALL

SELECT
  date_sk,
  i_item_id,
  i_category,
  net_paid,
  return_amount,
  sales_rank,
  'web' AS channel
FROM web_sales_returns

ORDER BY date_sk, channel, net_paid DESC
LIMIT 100
