WITH
  -- Sample a fraction of the inventory table
  inventory_sample AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
  ),
  -- Join sampled inventory to its warehouse
  inventory_cte AS (
    SELECT i.inv_warehouse_sk,
           SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
           w.w_warehouse_name,
           w.w_state,
           w.w_country
    FROM inventory_sample i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'TX'
      AND i.inv_quantity_on_hand > 0
    GROUP BY i.inv_warehouse_sk, w.w_warehouse_name, w.w_state, w.w_country
  ),
  -- Store sales enriched with customer, demographics, address and a left‑joined web page
  store_cte AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_education_status,
           ca.ca_state,
           ca.ca_country,
           ss.ss_sold_date_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_ext_sales_price,
           wp.wp_web_page_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ss.ss_ext_sales_price > 100
      AND cd.cd_gender = 'M'
      AND ca.ca_state = 'CA'
      AND ss.ss_quantity BETWEEN 1 AND 10
  ),
  -- Web sales enriched with ship mode, warehouse, web site, customer, demographics, address and a left‑joined web page
  web_cte AS (
    SELECT ws.ws_warehouse_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_ext_sales_price,
           sm.sm_type,
           sm.sm_ship_mode_id,
           wsite.web_site_id,
           wsite.web_county,
           c.c_customer_sk,
           cd.cd_gender,
           ca.ca_state,
           ca.ca_country,
           wp.wp_web_page_id
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ws.ws_ext_sales_price > 200
      AND sm.sm_type = 'AIR'
      AND wsite.web_county = 'Jefferson Davis Parish'
      AND ca.ca_country = 'United States'
  ),
  -- Distinct customer keys appearing in store sales
  cust_store AS (
    SELECT DISTINCT c_customer_sk FROM store_cte
  ),
  -- Distinct customer keys appearing in web sales
  cust_web AS (
    SELECT DISTINCT c_customer_sk FROM web_cte
  ),
  -- Customers that appear in store sales *but not* in web sales (EXCEPT)
  cust_only_store AS (
    SELECT c_customer_sk FROM cust_store
    EXCEPT
    SELECT c_customer_sk FROM cust_web
  ),
  -- Aggregate store‑side values per customer
  store_agg AS (
    SELECT c_customer_sk,
           MAX(c_first_name) AS c_first_name,
           MAX(c_last_name)  AS c_last_name,
           MAX(cd_gender)    AS store_gender,
           MAX(ca_state)     AS ca_state,
           SUM(ss_net_paid)  AS total_store_net_paid
    FROM store_cte
    GROUP BY c_customer_sk
  ),
  -- Aggregate web‑side values per warehouse (we will later join on the customer key that is also present)
  web_agg AS (
    SELECT ws_warehouse_sk,
           SUM(ws_net_paid) AS total_web_net_paid,
           MAX(c_customer_sk) AS c_customer_sk,
           MAX(cd_gender)    AS web_gender
    FROM web_cte
    GROUP BY ws_warehouse_sk
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY (COALESCE(sa.total_store_net_paid, 0) + COALESCE(wa.total_web_net_paid, 0)) DESC) AS row_num,
  COALESCE(sa.c_customer_sk, wa.c_customer_sk) AS customer_sk,
  sa.c_first_name,
  sa.c_last_name,
  sa.store_gender,
  wa.web_gender,
  sa.ca_state,
  sa.total_store_net_paid,
  wa.total_web_net_paid,
  inv.total_inventory_qty,
  (SELECT AVG(LENGTH(sm2.sm_code)) FROM ship_mode sm2 WHERE sm2.sm_type = 'AIR') AS avg_ship_code_len
FROM store_agg sa
FULL OUTER JOIN web_agg wa ON sa.c_customer_sk = wa.c_customer_sk
FULL OUTER JOIN inventory_cte inv ON wa.ws_warehouse_sk = inv.inv_warehouse_sk
WHERE (sa.total_store_net_paid > 500 OR wa.total_web_net_paid > 1000)
  AND (inv.total_inventory_qty IS NULL OR inv.total_inventory_qty > 50)
  AND (sa.store_gender = 'M' OR wa.web_gender = 'F')
  AND EXISTS (SELECT 1 FROM cust_only_store cos WHERE cos.c_customer_sk = sa.c_customer_sk)
ORDER BY (COALESCE(sa.total_store_net_paid, 0) + COALESCE(wa.total_web_net_paid, 0)) DESC
OFFSET 0
LIMIT 100
