WITH catalog_ret AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    d.d_date            AS activity_date,
    cr.cr_return_amount AS amount,
    CAST('CatalogReturn' AS varchar) AS source,
    s.s_store_name      AS store_name,
    cc.cc_name          AS cc_name
  FROM store s
  FULL OUTER JOIN call_center cc
    ON s.s_closed_date_sk = cc.cc_closed_date_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = COALESCE(s.s_closed_date_sk, cc.cc_closed_date_sk)
  JOIN date_dim d
    ON d.d_date_sk = cr.cr_returned_date_sk
  JOIN customer c
    ON c.c_customer_sk = cr.cr_refunded_customer_sk
  WHERE cr.cr_return_amount > 100
),
web_sales_ret AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    d.d_date            AS activity_date,
    ws.ws_ext_sales_price AS amount,
    CAST('WebSale' AS varchar) AS source,
    w.web_name          AS store_name,
    CAST(NULL AS varchar) AS cc_name
  FROM web_sales ws
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d
    ON d.d_date_sk = ws.ws_sold_date_sk
  JOIN web_site w
    ON w.web_site_sk = ws.ws_web_site_sk
  WHERE ws.ws_ext_sales_price > 100
)
SELECT
  u.c_customer_id,
  u.activity_date,
  u.amount,
  u.source,
  u.store_name,
  u.cc_name,
  (
    SELECT SUM(ws3.ws_ext_sales_price)
    FROM web_sales ws3
    WHERE ws3.ws_bill_customer_sk = u.c_customer_sk
  ) AS total_sales_amount
FROM (
  SELECT * FROM catalog_ret
  UNION
  SELECT * FROM web_sales_ret
) u
ORDER BY u.activity_date DESC, u.amount DESC
LIMIT 100
