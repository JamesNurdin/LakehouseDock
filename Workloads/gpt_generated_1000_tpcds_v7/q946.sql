WITH sr AS (
    SELECT *
    FROM store_returns
)
SELECT
    s.s_store_name,
    d_sr.d_year AS return_year,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(cd_s.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd_s.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers
FROM sr
JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_s
  ON sr.sr_cdemo_sk = cd_s.cd_demo_sk
JOIN customer_address ca_s
  ON sr.sr_addr_sk = ca_s.ca_address_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
  ON s.s_closed_date_sk = d_store.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d_sr.d_date_sk
JOIN date_dim d_inv
  ON i.inv_date_sk = d_inv.d_date_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_create
  ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sr.d_year = 2001
  AND cd_s.cd_purchase_estimate > 2000
GROUP BY s.s_store_name, d_sr.d_year
ORDER BY total_return_amount DESC
LIMIT 10
