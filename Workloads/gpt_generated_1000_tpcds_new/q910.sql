WITH
  ws_agg AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_quantity) AS total_qty,
      COUNT(*) AS ws_cnt,
      d.d_year,
      t.t_hour,
      i.i_current_price,
      p.p_discount_active,
      c.c_preferred_cust_flag,
      ca.ca_country,
      hd.hd_income_band_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2000
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 50
      AND p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
      AND ca.ca_country = 'United States'
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, d.d_year, t.t_hour,
             i.i_current_price, p.p_discount_active,
             c.c_preferred_cust_flag, ca.ca_country, hd.hd_income_band_sk
  ),
  cr_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      COUNT(*) AS cr_cnt,
      r.r_reason_desc,
      cp.cp_type,
      d2.d_year AS return_year,
      t2.t_hour AS return_hour,
      hd2.hd_income_band_sk AS return_hh_income
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd2 ON cr.cr_returning_hdemo_sk = hd2.hd_demo_sk
    WHERE d2.d_year = 2000
      AND t2.t_hour BETWEEN 9 AND 17
      AND cp.cp_type = 'Catalog'
      AND r.r_reason_desc <> ''
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk, r.r_reason_desc,
             cp.cp_type, d2.d_year, t2.t_hour, hd2.hd_income_band_sk
  ),
  intersect_items AS (
    SELECT ws_item_sk AS item_sk FROM ws_agg WHERE total_sales > 5000
    INTERSECT
    SELECT cr_item_sk AS item_sk FROM cr_agg WHERE total_return_amount > 1000
  ),
  final_base AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.total_sales,
      cr.total_return_amount,
      (ws.total_sales - cr.total_return_amount) AS net_sales,
      ws.hd_income_band_sk,
      cr.return_hh_income,
      ws.i_current_price,
      cr.r_reason_desc,
      cr.cp_type,
      CASE
        WHEN ws.total_sales > 10000 THEN 'High'
        WHEN ws.total_sales > 5000 THEN 'Medium'
        ELSE 'Low'
      END AS sales_category
    FROM ws_agg ws
    LEFT JOIN cr_agg cr
      ON ws.ws_item_sk = cr.cr_item_sk
     AND ws.ws_sold_date_sk = cr.cr_returned_date_sk
  )
SELECT
  fb.ws_item_sk AS item_sk,
  fb.ws_sold_date_sk AS date_sk,
  fb.total_sales,
  fb.total_return_amount,
  fb.net_sales,
  fb.sales_category,
  lt.income_flag,
  (SELECT MAX(net_sales) FROM final_base) AS max_net_sales_overall
FROM final_base fb
JOIN LATERAL (
  SELECT CASE
           WHEN fb.hd_income_band_sk BETWEEN 5 AND 7 THEN 'Middle'
           WHEN fb.hd_income_band_sk > 7 THEN 'High'
           ELSE 'Low'
         END AS income_flag
) lt ON true
WHERE fb.ws_item_sk IN (SELECT item_sk FROM intersect_items)
  AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = fb.ws_item_sk AND p.p_discount_active = 'Y')
UNION DISTINCT
SELECT
  fb.ws_item_sk AS item_sk,
  fb.ws_sold_date_sk AS date_sk,
  fb.total_sales,
  fb.total_return_amount,
  fb.net_sales,
  fb.sales_category,
  lt.income_flag,
  (SELECT MAX(net_sales) FROM final_base) AS max_net_sales_overall
FROM final_base fb
JOIN LATERAL (
  SELECT CASE
           WHEN fb.hd_income_band_sk BETWEEN 5 AND 7 THEN 'Middle'
           WHEN fb.hd_income_band_sk > 7 THEN 'High'
           ELSE 'Low'
         END AS income_flag
) lt ON true
WHERE fb.ws_item_sk NOT IN (SELECT item_sk FROM intersect_items)
  AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = fb.ws_item_sk AND p.p_discount_active = 'Y')
ORDER BY net_sales DESC
LIMIT 100
