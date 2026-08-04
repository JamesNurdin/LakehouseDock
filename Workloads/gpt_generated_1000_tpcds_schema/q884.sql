WITH
  ws_sample AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
  ),
  ws_agg AS (
    SELECT
      ws.ws_item_sk,
      i.i_category,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      AVG(ws.ws_ext_discount_amt) AS avg_discount,
      SUM(ws.ws_quantity) AS total_qty
    FROM ws_sample ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ext_list_price > 1000
      AND ws.ws_ship_hdemo_sk IN (983, 5032)
      AND ws.ws_sold_date_sk BETWEEN 2450836 AND 2451102
    GROUP BY ws.ws_item_sk, i.i_category
  ),
  cr_agg AS (
    SELECT
      cr.cr_item_sk,
      cc.cc_name,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450836 AND 2451102
      AND cr.cr_reason_sk = 1
      AND cr.cr_reversed_charge > 50
    GROUP BY cr.cr_item_sk, cc.cc_name
  ),
  inv_agg AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    WHERE inv.inv_date_sk BETWEEN 2450836 AND 2451102
    GROUP BY inv.inv_item_sk
  ),
  keys_ws AS (
    SELECT ws.ws_item_sk AS item_sk FROM ws_sample ws
  ),
  keys_cr AS (
    SELECT cr.cr_item_sk AS item_sk FROM catalog_returns cr
  ),
  except_keys AS (
    SELECT item_sk FROM keys_ws
    EXCEPT
    SELECT item_sk FROM keys_cr
  ),
  intersect_keys AS (
    SELECT item_sk FROM keys_ws
    INTERSECT
    SELECT item_sk FROM keys_cr
  ),
  union_agg AS (
    SELECT ws_item_sk AS item_sk, total_sales AS metric, 'sales' AS metric_type
    FROM ws_agg
    UNION
    SELECT cr_item_sk AS item_sk, total_return_amount AS metric, 'returns' AS metric_type
    FROM cr_agg
  ),
  full_joined AS (
    SELECT
      COALESCE(ws.ws_item_sk, cr.cr_item_sk, inv.inv_item_sk) AS item_sk,
      i.i_category,
      ws.total_sales,
      cr.total_return_amount,
      ws.avg_discount,
      ws.total_qty,
      inv.total_on_hand,
      cr.cc_name
    FROM ws_agg ws
    FULL OUTER JOIN cr_agg cr ON ws.ws_item_sk = cr.cr_item_sk
    FULL OUTER JOIN inv_agg inv ON COALESCE(ws.ws_item_sk, cr.cr_item_sk) = inv.inv_item_sk
    LEFT JOIN item i ON i.i_item_sk = COALESCE(ws.ws_item_sk, cr.cr_item_sk, inv.inv_item_sk)
  )
SELECT
  fj.item_sk,
  fj.i_category,
  fj.total_sales,
  fj.total_return_amount,
  fj.avg_discount,
  fj.total_qty,
  fj.total_on_hand,
  fj.cc_name,
  AVG(ua.metric) AS avg_metric
FROM full_joined fj
JOIN union_agg ua ON fj.item_sk = ua.item_sk
WHERE fj.item_sk IN (SELECT item_sk FROM intersect_keys)
  AND fj.item_sk NOT IN (SELECT item_sk FROM except_keys)
GROUP BY
  fj.item_sk,
  fj.i_category,
  fj.total_sales,
  fj.total_return_amount,
  fj.avg_discount,
  fj.total_qty,
  fj.total_on_hand,
  fj.cc_name
ORDER BY fj.total_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
