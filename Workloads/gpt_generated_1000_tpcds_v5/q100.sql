WITH joined_data AS (
  SELECT
    c.c_customer_id AS customer_id,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    ss.ss_net_paid AS store_net_paid,
    ws.ws_net_paid_inc_ship_tax AS web_net_paid,
    cr.cr_return_amount AS return_amount,
    cp.cp_type AS page_type
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                     AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
                           AND cr.cr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
                         AND cp.cp_start_date_sk = d.d_date_sk
  WHERE d.d_moy = 12
    AND c.c_preferred_cust_flag = 'Y'
    AND cd.cd_gender = 'M'
    AND hd.hd_buy_potential = 'HIGH'
    AND ss.ss_quantity > 2
    AND ws.ws_net_paid_inc_ship_tax > 100
    AND cr.cr_return_amount > 0
    AND cp.cp_type = 'PROMO'
)
SELECT
  customer_id,
  first_name,
  last_name,
  SUM(store_net_paid) AS total_store_sales,
  SUM(web_net_paid) AS total_web_sales,
  SUM(return_amount) AS total_returns,
  SUM(store_net_paid) + SUM(web_net_paid) - SUM(return_amount) AS total_sales,
  RANK() OVER (ORDER BY (SUM(store_net_paid) + SUM(web_net_paid) - SUM(return_amount)) DESC) AS sales_rank
FROM joined_data
GROUP BY customer_id, first_name, last_name
ORDER BY sales_rank, customer_id
LIMIT 100
