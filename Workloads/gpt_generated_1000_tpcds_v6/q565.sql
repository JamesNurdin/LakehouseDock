WITH joined_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    cr.cr_return_amount,
    i.i_item_id,
    i.i_category,
    i.i_current_price,
    cp.cp_department,
    ws.ws_quantity,
    ws.ws_sold_date_sk,
    td.t_hour,
    td.t_am_pm,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ws_site.web_city,
    ws_site.web_state,
    inv.inv_quantity_on_hand
  FROM web_sales ws
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib
    ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  WHERE i.i_current_price > 50
    AND ws_site.web_state = 'CA'
    AND cp.cp_department = 'Sports'
    AND inv.inv_quantity_on_hand > 100
    AND ib.ib_upper_bound <= 150000
),
agg_per_city_category AS (
  SELECT
    web_city,
    i_category,
    SUM(ws_net_paid) AS total_sales,
    SUM(cr_return_amount) AS total_returns,
    COUNT(DISTINCT ws_order_number) AS distinct_orders
  FROM joined_data
  GROUP BY web_city, i_category
)
SELECT
  web_city,
  AVG(total_sales) AS avg_sales_per_category,
  SUM(total_returns) AS sum_returns_all_categories,
  COUNT(DISTINCT i_category) AS category_count
FROM agg_per_city_category
GROUP BY web_city
HAVING AVG(total_sales) > 10000
ORDER BY avg_sales_per_category DESC
LIMIT 10
