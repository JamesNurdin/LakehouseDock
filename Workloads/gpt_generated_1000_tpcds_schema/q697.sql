WITH
  /* Sample a subset of web_sales */
  sampled_ws AS (
    SELECT *
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)   -- 10% random sample
  ),

  /* Date filter for the year 1915 */
  date_filtered AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM tpcds.date_dim
    WHERE d_year = 1915
  ),

  /* Time filter for business hours */
  time_filtered AS (
    SELECT t_time_sk, t_hour
    FROM tpcds.time_dim
    WHERE t_hour BETWEEN 9 AND 17
  ),

  /* Item filter for a specific brand */
  item_filtered AS (
    SELECT i_item_sk, i_brand, i_category, i_current_price
    FROM tpcds.item
    WHERE i_brand = 'exportiexporti #1'
  ),

  /* Promotion filter that references the item filter via IN subquery */
  promo_filtered AS (
    SELECT p_promo_sk, p_item_sk, p_discount_active, p_channel_event
    FROM tpcds.promotion
    WHERE p_discount_active = 'Y'
      AND p_item_sk IN (SELECT i_item_sk FROM tpcds.item WHERE i_brand = 'exportiexporti #1')
  ),

  /* Catalog page filter */
  catalog_page_filtered AS (
    SELECT cp_catalog_page_sk, cp_department, cp_end_date_sk
    FROM tpcds.catalog_page
    WHERE cp_department = 'Books'
  ),

  /* Web page filter */
  web_page_filtered AS (
    SELECT wp_web_page_sk, wp_url
    FROM tpcds.web_page
    WHERE wp_type = 'content'
  ),

  /* Store rows joined to date_dim (required join rule) */
  store_dates AS (
    SELECT s.s_store_sk, s.s_store_name, s.s_state, d.d_date_sk
    FROM tpcds.store s
    JOIN tpcds.date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
  ),

  /* Call‑center rows joined to date_dim (required join rule) */
  cc_dates AS (
    SELECT cc.cc_call_center_sk, cc.cc_name, cc.cc_state, d.d_date_sk
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE cc.cc_state = 'CA'
  ),

  /* Full outer join of store and call‑center on the date surrogate key */
  store_cc_full AS (
    SELECT
      COALESCE(s.d_date_sk, c.d_date_sk) AS d_date_sk,
      s.s_store_sk,
      s.s_store_name,
      c.cc_call_center_sk,
      c.cc_name
    FROM store_dates s
    FULL OUTER JOIN cc_dates c ON s.d_date_sk = c.d_date_sk
  ),

  /* Intersection of two key sets (item keys) */
  item_promo_intersect AS (
    SELECT ws.ws_item_sk AS item_key
    FROM sampled_ws ws
    WHERE ws.ws_quantity > 5
    INTERSECT
    SELECT i.i_item_sk
    FROM tpcds.item i
    WHERE i.i_current_price > 50
  )

SELECT
  final.item_key,
  COUNT(DISTINCT final.ws_order_number)               AS order_cnt,
  SUM(final.ws_ext_sales_price)                      AS total_sales,
  AVG(final.ws_ext_discount_amt)                    AS avg_discount,
  MIN(final.ws_net_profit)                           AS min_profit,
  MAX(final.ws_net_profit)                           AS max_profit
FROM (
  /* First branch of the UNION – distinct rows */
  SELECT
    ws.ws_item_sk      AS item_key,
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_net_profit,
    ws.ws_sold_date_sk
  FROM sampled_ws ws
  JOIN date_filtered d       ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_filtered t       ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item_filtered i       ON ws.ws_item_sk = i.i_item_sk
  JOIN promo_filtered p      ON ws.ws_promo_sk = p.p_promo_sk
  JOIN catalog_page_filtered cp ON cp.cp_end_date_sk = d.d_date_sk
  JOIN web_page_filtered wp  ON wp.wp_web_page_sk = ws.ws_web_page_sk
  JOIN store_cc_full scf     ON scf.d_date_sk = d.d_date_sk
  WHERE ws.ws_ext_sales_price > 100
    AND ws.ws_coupon_amt < 200
    AND i.i_category = 'Electronics'
    AND p.p_channel_event = 'N'
    AND ws.ws_ext_discount_amt > (
          SELECT AVG(ws2.ws_ext_discount_amt)
          FROM tpcds.web_sales ws2
        )

  UNION

  /* Second branch – same shape, different alias */
  SELECT
    ws2.ws_item_sk,
    ws2.ws_order_number,
    ws2.ws_ext_sales_price,
    ws2.ws_ext_discount_amt,
    ws2.ws_net_profit,
    ws2.ws_sold_date_sk
  FROM sampled_ws ws2
  JOIN date_filtered d2       ON ws2.ws_sold_date_sk = d2.d_date_sk
  JOIN time_filtered t2       ON ws2.ws_sold_time_sk = t2.t_time_sk
  JOIN item_filtered i2       ON ws2.ws_item_sk = i2.i_item_sk
  JOIN promo_filtered p2      ON ws2.ws_promo_sk = p2.p_promo_sk
  JOIN catalog_page_filtered cp2 ON cp2.cp_end_date_sk = d2.d_date_sk
  JOIN web_page_filtered wp2  ON wp2.wp_web_page_sk = ws2.ws_web_page_sk
  JOIN store_cc_full scf2     ON scf2.d_date_sk = d2.d_date_sk
  WHERE ws2.ws_ext_sales_price > 100
    AND ws2.ws_coupon_amt < 200
    AND i2.i_category = 'Electronics'
    AND p2.p_channel_event = 'N'
    AND ws2.ws_ext_discount_amt > (
          SELECT AVG(ws3.ws_ext_discount_amt)
          FROM tpcds.web_sales ws3
        )
) final
WHERE final.item_key IN (SELECT item_key FROM item_promo_intersect)
GROUP BY final.item_key
ORDER BY total_sales DESC
LIMIT 100
