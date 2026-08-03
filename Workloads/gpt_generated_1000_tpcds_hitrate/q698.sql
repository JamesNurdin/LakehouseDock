WITH
  cr_agg AS (
    SELECT
      cr_item_sk,
      cr_returned_date_sk,
      cr_refunded_customer_sk,
      SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_fy_year = 1915)
    GROUP BY cr_item_sk, cr_returned_date_sk, cr_refunded_customer_sk
  ),
  wr_agg AS (
    SELECT
      wr_item_sk,
      wr_returned_date_sk,
      wr_refunded_customer_sk,
      SUM(wr_return_amt) AS total_wr_amount
    FROM web_returns
    WHERE wr_return_amt > 0
      AND wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_fy_year = 1915)
    GROUP BY wr_item_sk, wr_returned_date_sk, wr_refunded_customer_sk
  ),
  ws_agg AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_ext_sales_price > 0
      AND ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_fy_year = 1915)
    GROUP BY ws_item_sk, ws_sold_date_sk
  ),
  combined AS (
    SELECT
      cr_item_sk      AS item_sk,
      cr_returned_date_sk AS date_sk,
      cr_refunded_customer_sk AS cust_sk,
      total_return_amount   AS return_amount,
      CAST(NULL AS decimal(7,2)) AS sales_amount,
      'catalog' AS src
    FROM cr_agg
    UNION DISTINCT
    SELECT
      wr_item_sk,
      wr_returned_date_sk,
      wr_refunded_customer_sk,
      total_wr_amount,
      CAST(NULL AS decimal(7,2)),
      'web_ret'
    FROM wr_agg
  ),
  enriched AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      d.d_date,
      d.d_month_seq,
      c.c_customer_id,
      c.c_birth_country,
      ca.return_amount,
      COALESCE(ws.total_sales, 0) AS sales_amount,
      CASE WHEN ca.return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category,
      SUM(ca.return_amount) OVER (PARTITION BY i.i_item_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_return_total,
      p.p_promo_name
    FROM combined ca
    JOIN item i       ON ca.item_sk = i.i_item_sk
    JOIN date_dim d   ON ca.date_sk = d.d_date_sk
    JOIN customer c   ON ca.cust_sk = c.c_customer_sk
    LEFT JOIN ws_agg ws ON ca.item_sk = ws.ws_item_sk AND ca.date_sk = ws.ws_sold_date_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
                           AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  )
SELECT
  i_item_id,
  i_product_name,
  d_date,
  c_customer_id,
  c_birth_country,
  return_amount,
  sales_amount,
  return_category,
  running_return_total,
  p_promo_name
FROM enriched
WHERE return_category = 'High'
  AND d_month_seq BETWEEN 1 AND 12
  AND c_birth_country = 'United States'
ORDER BY running_return_total DESC
LIMIT 100
