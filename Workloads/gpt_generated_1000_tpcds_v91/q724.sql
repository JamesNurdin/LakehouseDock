WITH catalog_agg AS (
  SELECT
    i.i_item_sk AS i_item_sk,
    i.i_product_name AS product_name,
    'Catalog' AS channel,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    (
      SELECT SUM(sr.sr_return_amt)
      FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
    ) AS total_return_amt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_ext_sales_price > 0
    AND EXISTS (
      SELECT 1
      FROM store_returns sr_check
      WHERE sr_check.sr_item_sk = i.i_item_sk
        AND sr_check.sr_return_amt > 0
    )
  GROUP BY i.i_item_sk, i.i_product_name
),
web_agg AS (
  SELECT
    i.i_item_sk AS i_item_sk,
    i.i_product_name AS product_name,
    'Web' AS channel,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    (
      SELECT SUM(sr.sr_return_amt)
      FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
    ) AS total_return_amt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  WHERE ws.ws_ext_sales_price > 0
    AND EXISTS (
      SELECT 1
      FROM store_returns sr_check
      WHERE sr_check.sr_item_sk = i.i_item_sk
        AND sr_check.sr_return_amt > 0
    )
  GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
  ca.i_item_sk,
  ca.product_name,
  ca.channel,
  ca.total_sales,
  ca.order_cnt,
  ca.total_return_amt
FROM catalog_agg ca
UNION ALL
SELECT
  wa.i_item_sk,
  wa.product_name,
  wa.channel,
  wa.total_sales,
  wa.order_cnt,
  wa.total_return_amt
FROM web_agg wa
ORDER BY total_sales DESC
LIMIT 100
