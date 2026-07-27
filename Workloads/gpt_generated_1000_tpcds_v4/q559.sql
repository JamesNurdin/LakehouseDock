WITH agg1 AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    r_cat.r_reason_sk,
    r_cat.r_reason_desc,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM item i
  JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
  JOIN reason r_cat
    ON cr.cr_reason_sk = r_cat.r_reason_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
  JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
  WHERE i.i_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_city IN ('Friendship','Highland Park')
    AND r_cat.r_reason_desc LIKE '%damaged%'
  GROUP BY
    i.i_item_sk,
    i.i_product_name,
    r_cat.r_reason_sk,
    r_cat.r_reason_desc
),
agg2 AS (
  SELECT
    i_item_sk,
    i_product_name,
    SUM(catalog_net_profit) AS sum_catalog_profit,
    SUM(web_net_profit) AS sum_web_profit,
    SUM(catalog_return_loss) AS sum_catalog_loss,
    SUM(web_return_loss) AS sum_web_loss,
    SUM(catalog_net_profit + web_net_profit - catalog_return_loss - web_return_loss) AS total_net,
    COUNT(*) AS reason_count
  FROM agg1
  GROUP BY i_item_sk, i_product_name
)
SELECT
  i_item_sk,
  i_product_name,
  total_net,
  reason_count,
  total_net / reason_count AS avg_net_per_reason,
  ROW_NUMBER() OVER (ORDER BY total_net DESC) AS revenue_rank
FROM agg2
WHERE total_net > 0
ORDER BY total_net DESC
LIMIT 100
