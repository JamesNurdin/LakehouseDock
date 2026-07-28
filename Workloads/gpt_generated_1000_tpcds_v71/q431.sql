WITH
  store_sales_agg AS (
    SELECT
      ss.ss_customer_sk AS customer_sk,
      SUM(ss.ss_ext_sales_price) AS total_store_sales,
      SUM(ss.ss_ext_discount_amt) AS total_store_discount,
      COUNT(DISTINCT ss.ss_item_sk) AS distinct_store_items
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1980
      AND cd.cd_gender = 'M'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_customer_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      SUM(ws.ws_ext_sales_price) AS ws_total_sales,
      SUM(ws.ws_ext_discount_amt) AS ws_total_discount
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_ship_cost > 100
    GROUP BY ws.ws_bill_customer_sk
  )
SELECT
  final.c_customer_id,
  final.c_first_name,
  final.c_last_name,
  final.cd_education_status,
  final.w_warehouse_name,
  final.wp_url,
  final.total_store_sales,
  final.total_store_discount,
  final.ws_total_sales,
  final.ws_total_discount,
  final.return_count,
  ROW_NUMBER() OVER (PARTITION BY final.c_customer_sk ORDER BY final.total_store_sales DESC) AS sales_rank
FROM (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_education_status,
    w.w_warehouse_name,
    wp.wp_url,
    ss_agg.total_store_sales,
    ss_agg.total_store_discount,
    ws_agg.ws_total_sales,
    ws_agg.ws_total_discount,
    COUNT(sr.sr_return_quantity) AS return_count
  FROM store_sales_agg ss_agg
  JOIN customer c ON ss_agg.customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_sales_agg ws_agg ON ws.ws_bill_customer_sk = ws_agg.customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE wp.wp_char_count > 2000
    AND w.w_state = 'CA'
    AND ws.ws_ext_ship_cost > 100
    AND EXISTS (
          SELECT 1 FROM inventory i2
          WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
            AND i2.inv_quantity_on_hand > 5000
        )
  GROUP BY
    c.c_customer_sk,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_education_status,
    w.w_warehouse_name,
    wp.wp_url,
    ss_agg.total_store_sales,
    ss_agg.total_store_discount,
    ws_agg.ws_total_sales,
    ws_agg.ws_total_discount
) final
ORDER BY final.total_store_sales DESC
LIMIT 100
