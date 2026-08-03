WITH joined_data AS (
   SELECT
      d.d_year,
      d.d_date,
      ss.ss_store_sk,
      ss.ss_net_paid,
      LAG(ss.ss_net_paid) OVER (PARTITION BY ss.ss_store_sk ORDER BY d.d_date) AS lag_net_paid,
      cr.cr_return_amount,
      i.inv_quantity_on_hand,
      p.p_cost,
      r.r_reason_id,
      cd.cd_gender,
      wp.wp_type
   FROM
      date_dim d
      JOIN (SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)) ss
           ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN web_sales ws
           ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN catalog_returns cr
           ON cr.cr_returned_date_sk = d.d_date_sk
      JOIN inventory i
           ON i.inv_date_sk = d.d_date_sk
      JOIN promotion p
           ON p.p_start_date_sk = d.d_date_sk
      JOIN reason r
           ON cr.cr_reason_sk = r.r_reason_sk
      JOIN warehouse w
           ON cr.cr_warehouse_sk = w.w_warehouse_sk
      JOIN customer c
           ON cr.cr_refunded_customer_sk = c.c_customer_sk
      JOIN customer_address ca
           ON cr.cr_refunded_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd
           ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
      JOIN web_page wp
           ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE
      d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.inv_quantity_on_hand > 500
      AND r.r_reason_id = 'AAAAAAAAIAAAAAAA'
)
SELECT
   d_year,
   SUM(cr_return_amount) AS total_return_amount,
   SUM(ss_net_paid) AS total_sales,
   AVG(inv_quantity_on_hand) AS avg_inventory,
   COUNT(DISTINCT ss_store_sk) AS store_count,
   MAX(p_cost) AS max_promo_cost,
   AVG(lag_net_paid) AS avg_lag_net_paid
FROM joined_data
GROUP BY d_year
ORDER BY total_sales DESC
LIMIT 100
