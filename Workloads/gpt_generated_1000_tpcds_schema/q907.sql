WITH
  sales_data AS (
    SELECT
      cs.cs_sold_date_sk AS date_sk,
      d.d_year,
      cp.cp_catalog_page_id,
      sm.sm_type,
      c.c_customer_id,
      ca.ca_state,
      cd.cd_gender,
      cs.cs_order_number,
      cs.cs_net_paid,
      cr.cr_return_amount,
      cr.cr_return_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'OVERNIGHT'
      AND cp.cp_catalog_number BETWEEN 10 AND 20
  ),
  store_data AS (
    SELECT
      ss.ss_sold_date_sk AS date_sk,
      d.d_year,
      c.c_customer_id,
      ca.ca_state,
      cd.cd_gender,
      ss.ss_ticket_number,
      ss.ss_net_paid,
      inv.inv_quantity_on_hand,
      city_word
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
      AND inv.inv_item_sk = ss.ss_item_sk
    CROSS JOIN UNNEST(split(ca.ca_city, ' ')) AS t(city_word)
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND ss.ss_net_paid > 0
  )
SELECT
  COALESCE(s.date_sk, st.date_sk) AS date_sk,
  COALESCE(s.d_year, st.d_year) AS d_year,
  COUNT(DISTINCT s.cs_order_number) AS num_orders,
  SUM(s.cs_net_paid) AS total_sales,
  SUM(s.cr_return_amount) AS total_returns,
  SUM(st.ss_net_paid) AS total_store_sales,
  AVG(st.inv_quantity_on_hand) AS avg_inventory_qty,
  COUNT(DISTINCT st.city_word) AS distinct_city_words
FROM sales_data s
FULL OUTER JOIN store_data st ON s.date_sk = st.date_sk
GROUP BY 1, 2
HAVING SUM(s.cs_net_paid) > 10000
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
