WITH base_metrics AS (
   SELECT
       s.s_store_id,
       d_ss.d_year,
       ws.ws_sold_date_sk,
       wsite.web_site_id,
       SUM(ws.ws_ext_sales_price) AS web_sales_amount,
       SUM(ss.ss_ext_sales_price) AS store_sales_amount,
       SUM(sr.sr_return_amt) AS store_return_amount
   FROM store s
   JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
   JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                        AND sr.sr_item_sk = ss.ss_item_sk
   JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
   JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d_ss.d_date_sk
   JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
   JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
   JOIN call_center cc ON cc.cc_open_date_sk = d_wp_create.d_date_sk
   JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
   JOIN catalog_page cp ON cp.cp_start_date_sk = d_wp_access.d_date_sk
   JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
   JOIN date_dim d_ws_open ON wsite.web_open_date_sk = d_ws_open.d_date_sk
   JOIN date_dim d_ws_close ON wsite.web_close_date_sk = d_ws_close.d_date_sk
   WHERE d_ss.d_year = 2001
     AND t_ws.t_hour BETWEEN 8 AND 20
     AND s.s_state = 'CA'
   GROUP BY s.s_store_id, d_ss.d_year, ws.ws_sold_date_sk, wsite.web_site_id
),

cubed_agg AS (
   SELECT
       s_store_id,
       d_year,
       web_site_id,
       SUM(web_sales_amount) AS total_web_sales,
       SUM(store_sales_amount) AS total_store_sales,
       SUM(store_return_amount) AS total_returns
   FROM base_metrics
   GROUP BY CUBE (s_store_id, d_year, web_site_id)
   HAVING SUM(store_sales_amount) > 5000
),

ranked AS (
   SELECT
       s_store_id,
       d_year,
       web_site_id,
       total_web_sales,
       total_store_sales,
       total_returns,
       ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_store_sales DESC) AS rn
   FROM cubed_agg
)
SELECT
    r.s_store_id,
    r.d_year,
    r.web_site_id,
    r.total_web_sales,
    r.total_store_sales,
    r.total_returns
FROM ranked r
WHERE r.rn <= 5
  AND r.s_store_id IN (
        SELECT s_store_id FROM store
        EXCEPT
        SELECT s_store_id FROM store WHERE s_number_employees < 5
  )
LIMIT 100
