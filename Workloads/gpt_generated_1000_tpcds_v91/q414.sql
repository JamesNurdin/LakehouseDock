WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_hdemo_sk,
    ss.ss_addr_sk,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    ss.ss_quantity,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    i.i_item_id,
    i.i_category,
    i.i_current_price,
    c.c_customer_id,
    c.c_birth_year,
    ca.ca_state,
    ca.ca_city,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    w.w_warehouse_name,
    w.w_city,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    wp.wp_image_count,
    wp.wp_link_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                      AND inv.inv_date_sk = d.d_date_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                   AND wp.wp_creation_date_sk = d.d_date_sk
)
SELECT
  d_year,
  i_category,
  ca_state,
  w_warehouse_name,
  url_segment,
  SUM(ss_ext_sales_price) AS total_sales,
  AVG(ss_ext_sales_price) AS avg_sales,
  COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
  SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
  SUM(hd_dep_count) AS total_dependents,
  COUNT(DISTINCT wp_image_count) AS distinct_image_counts
FROM base
CROSS JOIN UNNEST(split(wp_url, '/')) AS t (url_segment)
WHERE d_year = 2001
  AND hd_income_band_sk = 18
  AND i_current_price > 100.00
  AND t_hour BETWEEN 9 AND 17
GROUP BY
  d_year,
  i_category,
  ca_state,
  w_warehouse_name,
  url_segment
ORDER BY total_sales DESC
LIMIT 100
