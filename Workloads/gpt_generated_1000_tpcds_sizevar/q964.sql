WITH
  cte1 AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_net_paid,
      regexp_extract(CAST(ws.ws_order_number AS VARCHAR), '(\\d{3})', 1) AS order_prefix,
      substring(CAST(ws.ws_order_number AS VARCHAR), 1, 5) AS order_substr
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(CAST(ws.ws_order_number AS VARCHAR), '^\\d{9}$')
  ),
  cte2 AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      cr.cr_return_amount,
      regexp_extract(CAST(cr.cr_reason_sk AS VARCHAR), '(\\d+)', 1) AS reason_code,
      cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 0
  ),
  full_join AS (
    SELECT
      coalesce(c1.ws_sold_date_sk, c2.cr_returned_date_sk) AS date_sk,
      c1.ws_item_sk,
      c2.cr_item_sk,
      c1.ws_net_paid,
      c2.cr_return_amount,
      c1.order_prefix,
      c2.reason_code
    FROM cte1 c1
    FULL OUTER JOIN cte2 c2
      ON c1.ws_item_sk = c2.cr_item_sk
     AND c1.ws_sold_date_sk = c2.cr_returned_date_sk
  ),
  lateral_cte AS (
    SELECT
      fj.*,
      lt.total_quantity
    FROM full_join fj
    CROSS JOIN LATERAL (
      SELECT sum(ws2.ws_quantity) AS total_quantity
      FROM web_sales ws2
      WHERE ws2.ws_item_sk = fj.ws_item_sk
        AND ws2.ws_sold_date_sk = fj.date_sk
    ) lt
  ),
  unioned AS (
    SELECT
      date_sk,
      ws_item_sk      AS item_sk,
      ws_net_paid     AS metric,
      order_prefix    AS label
    FROM lateral_cte
    WHERE ws_net_paid IS NOT NULL
    UNION
    SELECT
      date_sk,
      cr_item_sk      AS item_sk,
      cr_return_amount AS metric,
      reason_code     AS label
    FROM lateral_cte
    WHERE cr_return_amount IS NOT NULL
  ),
  intersected AS (
    SELECT item_sk, metric
    FROM unioned
    INTERSECT
    SELECT ws.ws_item_sk, ws.ws_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  )
SELECT
  i.item_sk,
  sum(i.metric) AS total_metric,
  count(*) AS cnt
FROM intersected i
GROUP BY GROUPING SETS ((i.item_sk), ())
ORDER BY total_metric DESC
LIMIT 100
