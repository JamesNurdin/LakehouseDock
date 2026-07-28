WITH joined_data AS (
   SELECT
      d.d_year,
      ca.ca_state,
      ss.ss_item_sk,
      ss.ss_ext_sales_price,
      sr.sr_return_amt,
      cr.cr_return_amount,
      ws.ws_ext_sales_price,
      i.inv_quantity_on_hand,
      w.w_warehouse_name,
      w.w_warehouse_sq_ft,
      hd.hd_income_band_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                          AND sr.sr_item_sk = ss.ss_item_sk
   JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                            AND cr.cr_returned_time_sk = t.t_time_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN inventory i ON i.inv_date_sk = d.d_date_sk
                      AND i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                       AND ws.ws_sold_time_sk = t.t_time_sk
                       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                       AND ws.ws_bill_addr_sk = ca.ca_address_sk
                       AND ws.ws_web_page_sk = wp.wp_web_page_sk
                       AND ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2001
     AND t.t_hour BETWEEN 8 AND 16
     AND ca.ca_state IN ('CA', 'TX')
     AND w.w_warehouse_sq_ft > 150000
     AND hd.hd_income_band_sk = 7
     AND i.inv_quantity_on_hand BETWEEN 50 AND 500
     AND d.d_month_seq = 120
     AND EXISTS (
          SELECT 1 FROM web_page wp_check
          WHERE wp_check.wp_web_page_sk = ws.ws_web_page_sk
            AND wp_check.wp_type = 'content'
        )
),
agg1 AS (
   SELECT
      d_year,
      ca_state,
      ss_item_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(sr_return_amt) AS total_store_returns,
      SUM(cr_return_amount) AS total_catalog_returns,
      AVG(inv_quantity_on_hand) AS avg_inventory_qty,
      MAX(w_warehouse_sq_ft) AS max_warehouse_sq_ft
   FROM joined_data
   GROUP BY d_year, ca_state, ss_item_sk
)
SELECT
   d_year,
   ca_state,
   ss_item_sk,
   total_sales,
   total_store_returns,
   total_catalog_returns,
   (total_sales - total_store_returns - total_catalog_returns) AS net_revenue,
   avg_inventory_qty,
   (
       SELECT MAX(w_warehouse_sq_ft)
       FROM (
           SELECT DISTINCT w_warehouse_sq_ft
           FROM warehouse w2
           WHERE w2.w_state = agg1.ca_state
       ) sub
   ) AS max_warehouse_sq_ft_state
FROM agg1
WHERE (total_sales - total_store_returns - total_catalog_returns) > 10000
ORDER BY net_revenue DESC
LIMIT 100
