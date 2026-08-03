WITH
  ws_agg AS (
    SELECT
      ws_web_page_sk,
      ws_web_site_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      AVG(ws_net_profit) AS avg_profit,
      COUNT(*) AS cnt_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002 AND d_month_seq BETWEEN 1 AND 12
      )
      AND ws_quantity > 1
      AND ws_list_price >= 100
      AND ws_ship_mode_sk = 5
      AND ws_wholesale_cost < 500
      AND ws_coupon_amt = 0
    GROUP BY ws_web_page_sk, ws_web_site_sk
  ),
  selected_keys AS (
    SELECT DISTINCT ws_order_number
    FROM web_sales
    WHERE ws_net_paid_inc_tax > 1500
      AND ws_ship_date_sk IS NOT NULL
      AND ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_current_month = 'Y')
      AND ws_web_page_sk IN (SELECT wp_web_page_sk FROM web_page WHERE wp_type = 'content')
      AND ws_web_site_sk IN (SELECT web_site_sk FROM web_site WHERE web_class = 'A')
      AND ws_quantity BETWEEN 2 AND 10
  ),
  excluded_keys AS (
    SELECT DISTINCT ws_order_number
    FROM web_sales
    WHERE ws_net_paid_inc_tax < 500
      AND ws_quantity = 1
  ),
  intersect_pages AS (
    SELECT wp_web_page_id AS page_id FROM web_page WHERE wp_char_count > 1000
    INTERSECT
    SELECT cp_catalog_page_id FROM catalog_page WHERE cp_department = 'Sports'
  ),
  agg_joined AS (
    SELECT
      d.d_year AS year,
      ws_agg.ws_web_page_sk,
      wp.wp_web_page_id AS page_id,
      wp.wp_url AS url,
      ws_agg.total_sales,
      ws_agg.avg_profit,
      ws_agg.cnt_sales,
      CASE
        WHEN ws_agg.total_sales > 100000 THEN 'High'
        WHEN ws_agg.total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
      END AS sales_category,
      (
        SELECT SUM(sr_net_loss)
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk = d.d_date_sk
          AND sr.sr_store_sk = 1
      ) AS store_loss_on_date,
      ws_agg.total_sales - COALESCE(
        (
          SELECT SUM(sr_net_loss)
          FROM store_returns sr
          WHERE sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_store_sk = 1
        ),
        0
      ) AS net_sales_adj
    FROM ws_agg
    JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws_agg.ws_web_site_sk = ws.web_site_sk
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
      AND ws.web_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1 AND 12
      AND cp.cp_catalog_number IN (9, 11, 14)
      AND wp.wp_type = 'content'
      AND ws.web_class = 'A'
      AND cp.cp_type = 'catalog'
      AND d.d_current_month = 'Y'
      AND d.d_holiday = 'N'
      AND wp.wp_web_page_id NOT IN (SELECT page_id FROM intersect_pages)
      AND ws_agg.ws_web_page_sk NOT IN (SELECT ws_order_number FROM excluded_keys)
  )
SELECT
  year,
  ws_web_page_sk,
  page_id,
  url,
  total_sales,
  avg_profit,
  cnt_sales,
  sales_category,
  store_loss_on_date,
  net_sales_adj
FROM agg_joined
WHERE ws_web_page_sk IN (
  SELECT ws_order_number FROM selected_keys
  EXCEPT
  SELECT ws_order_number FROM excluded_keys
)
ORDER BY year DESC, total_sales DESC
LIMIT 100
