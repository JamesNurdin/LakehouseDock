WITH joined AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_state AS store_state,
    d_sales.d_year AS sales_year,
    ss.ss_ext_sales_price AS sales_amount,
    ss.ss_net_profit AS sales_profit,
    COALESCE(sr.sr_return_amt, 0) AS return_amount,
    i.inv_quantity_on_hand AS inventory_qty,
    c.c_salutation AS customer_salutation,
    cp.cp_catalog_number AS catalog_number,
    wp.wp_url AS page_url,
    wr.wr_return_amt AS web_return_amount,
    ws2.web_name AS website_name
  FROM store_sales ss
  JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
  LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
  LEFT JOIN inventory i ON i.inv_date_sk = d_sales.d_date_sk
  LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
  LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_sales.d_date_sk
  LEFT JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
  LEFT JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_returned_date_sk = d_sales.d_date_sk
  LEFT JOIN date_dim d_web_ret ON wr.wr_returned_date_sk = d_web_ret.d_date_sk
  LEFT JOIN web_site ws2 ON ws2.web_open_date_sk = d_sales.d_date_sk
  LEFT JOIN date_dim d_ws ON ws2.web_open_date_sk = d_ws.d_date_sk
  WHERE d_sales.d_year = 2000
    AND s.s_state = 'CA'
    AND c.c_salutation = 'Mr.'
)
SELECT
  store_id,
  sales_year,
  total_sales,
  total_profit,
  total_returns,
  total_inventory,
  ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_sales DESC) AS sales_rank
FROM (
  SELECT
    store_id,
    sales_year,
    SUM(sales_amount) AS total_sales,
    SUM(sales_profit) AS total_profit,
    SUM(return_amount) AS total_returns,
    SUM(inventory_qty) AS total_inventory
  FROM joined
  GROUP BY store_id, sales_year
) agg
ORDER BY total_sales DESC
LIMIT 10
