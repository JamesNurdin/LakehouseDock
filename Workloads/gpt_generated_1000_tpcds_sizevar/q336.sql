WITH catalog_agg AS (
  SELECT
    i.i_item_sk,
    d.d_year,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'high' ELSE 'low' END AS sales_category
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
    AND i.i_size IN ('small', 'large')
    AND p.p_discount_active = 'Y'
    AND cc.cc_country = 'United States'
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc LIKE '%damaged%'
  GROUP BY i.i_item_sk, d.d_year
  HAVING SUM(cs.cs_net_paid) > 5000
),

web_agg AS (
  SELECT
    i.i_item_sk,
    d.d_year,
    SUM(ws.ws_net_paid) AS total_ws_sales,
    SUM(wr.wr_return_amt) AS total_ws_returns,
    COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt,
    CASE WHEN SUM(ws.ws_net_paid) > 8000 THEN 'high' ELSE 'low' END AS ws_sales_category
  FROM web_sales ws
  JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
    AND i.i_units = 'Lb'
    AND p.p_discount_active = 'Y'
    AND sm.sm_carrier = 'UPS'
    AND r.r_reason_desc = 'customer not satisfied'
    AND ws.ws_sales_price > 0
  GROUP BY i.i_item_sk, d.d_year
  HAVING SUM(ws.ws_net_paid) > 4000
),

store_agg AS (
  SELECT
    i.i_item_sk,
    d.d_year,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt
  FROM store_returns sr
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
    AND i.i_category = 'Electronics'
    AND r.r_reason_desc NOT LIKE '%defective%'
    AND sr.sr_return_quantity > 0
    AND sr.sr_fee < 10
    AND sr.sr_return_ship_cost BETWEEN 0 AND 20
  GROUP BY i.i_item_sk, d.d_year
),

intersect_items AS (
  SELECT i_item_sk FROM catalog_agg WHERE sales_category = 'high'
  INTERSECT
  SELECT i_item_sk FROM web_agg WHERE ws_sales_category = 'high'
)

SELECT
  ca.d_year,
  ca.i_item_sk,
  i.i_product_name,
  ca.total_sales,
  wa.total_ws_sales,
  sa.total_store_returns,
  CASE
    WHEN ca.total_sales > wa.total_ws_sales THEN 'Catalog dominates'
    ELSE 'Web dominates'
  END AS dominance
FROM intersect_items ii
JOIN catalog_agg ca
  ON ii.i_item_sk = ca.i_item_sk
JOIN web_agg wa
  ON ii.i_item_sk = wa.i_item_sk
LEFT JOIN store_agg sa
  ON ii.i_item_sk = sa.i_item_sk AND ca.d_year = sa.d_year
JOIN item i
  ON ii.i_item_sk = i.i_item_sk
WHERE ca.d_year = 2001
ORDER BY ca.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
