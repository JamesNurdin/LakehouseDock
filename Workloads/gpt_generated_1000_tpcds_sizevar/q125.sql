WITH web_agg AS (
  SELECT
    i.i_category,
    SUM(ws.ws_ext_sales_price) AS total_amount
  FROM tpcds.web_sales ws
  JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450808 AND 2451093
    AND i.i_category_id IN (1, 2, 5)
  GROUP BY i.i_category
),
web_ranked AS (
  SELECT
    wa.i_category,
    CASE WHEN wa.total_amount > 50000 THEN 'High' ELSE 'Low' END AS sales_level,
    wa.total_amount,
    ROW_NUMBER() OVER (PARTITION BY wa.i_category ORDER BY wa.total_amount DESC) AS rank_in_category,
    (SELECT AVG(i_current_price) FROM tpcds.item ii WHERE ii.i_category = wa.i_category) AS avg_price,
    'web' AS source
  FROM web_agg wa
),
catalog_agg AS (
  SELECT
    i.i_category,
    SUM(cr.cr_return_amount) AS total_amount
  FROM tpcds.catalog_returns cr
  JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
  JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450808 AND 2451093
    AND cc.cc_city = 'Georgetown'
  GROUP BY i.i_category
),
catalog_ranked AS (
  SELECT
    ca.i_category,
    CASE WHEN ca.total_amount > 20000 THEN 'High' ELSE 'Low' END AS sales_level,
    ca.total_amount,
    ROW_NUMBER() OVER (PARTITION BY ca.i_category ORDER BY ca.total_amount DESC) AS rank_in_category,
    (SELECT AVG(i_current_price) FROM tpcds.item ii WHERE ii.i_category = ca.i_category) AS avg_price,
    'catalog' AS source
  FROM catalog_agg ca
),
combined AS (
  SELECT * FROM web_ranked
  UNION ALL
  SELECT * FROM catalog_ranked
)
SELECT
  i_category,
  sales_level,
  total_amount,
  rank_in_category,
  avg_price,
  source
FROM combined
ORDER BY i_category, rank_in_category
