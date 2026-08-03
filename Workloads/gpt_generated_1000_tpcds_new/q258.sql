WITH
  -- Catalog fact joined to its dimensions and returns
  catalog_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_paid,
      cc.cc_name,
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_buy_potential,
      cr.cr_return_quantity,
      ROW_NUMBER() OVER (ORDER BY cs.cs_order_number) AS rn
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.catalog_returns cr
      ON cs.cs_item_sk = cr.cr_item_sk
     AND cs.cs_order_number = cr.cr_order_number
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cc.cc_state = 'CA'
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cd.cd_credit_rating = 'AA'
      AND hd.hd_income_band_sk = 5
      AND cs.cs_net_paid > 1000
  ),
  -- Web fact joined to its dimensions and page
  web_join AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_net_paid,
      wp.wp_type,
      c.c_customer_id AS web_customer_id,
      cd.cd_gender AS web_gender,
      hd.hd_buy_potential AS web_buy_potential,
      ROW_NUMBER() OVER (ORDER BY ws.ws_order_number) AS rn_ws
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND wp.wp_type = 'content'
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count >= 2
      AND ws.ws_net_paid > 500
  ),
  -- Store fact with a RIGHT OUTER JOIN to keep all customers
  store_right AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_net_paid,
      c.c_customer_id AS store_customer_id,
      cd.cd_gender AS store_gender,
      hd.hd_buy_potential AS store_buy_potential,
      ROW_NUMBER() OVER (ORDER BY ss.ss_ticket_number) AS rn_store
    FROM tpcds.store_sales ss
    RIGHT JOIN tpcds.customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
      AND c.c_salutation = 'Mr.'
      AND cd.cd_education_status = 'College'
      AND hd.hd_income_band_sk = 3
      AND ss.ss_net_paid > 200
  ),
  -- Unnest an artificial status array for each catalog row
  catalog_status AS (
    SELECT
      cj.cs_order_number,
      status,
      cj.rn
    FROM catalog_join cj
    CROSS JOIN UNNEST(ARRAY['shipped','returned','cancelled']) AS t(status)
    WHERE status <> 'cancelled'
  ),
  -- Intersect order numbers that appear both in catalog and web streams
  intersect_orders AS (
    SELECT cs_order_number AS order_number FROM catalog_join
    INTERSECT
    SELECT ws_order_number FROM web_join
  ),
  -- Second intersection with store tickets (to keep only orders that also have a matching store ticket)
  intersect_all AS (
    SELECT order_number FROM intersect_orders
    INTERSECT
    SELECT ss_ticket_number FROM store_right
  ),
  -- Aggregate over the intersected keys
  final_agg AS (
    SELECT
      io.order_number,
      AVG(cj.cs_net_paid) AS avg_catalog_net_paid,
      AVG(wj.ws_net_paid) AS avg_web_net_paid,
      COUNT(*) AS num_sources,
      MIN(cj.rn) AS min_catalog_rn
    FROM intersect_all io
    LEFT JOIN catalog_join cj ON io.order_number = cj.cs_order_number
    LEFT JOIN web_join wj   ON io.order_number = wj.ws_order_number
    GROUP BY io.order_number
    HAVING COUNT(*) > 1
  )
SELECT
  fa.order_number,
  fa.avg_catalog_net_paid,
  fa.avg_web_net_paid,
  fa.num_sources,
  fa.min_catalog_rn,
  cs.status,
  cs.rn AS catalog_row_number
FROM final_agg fa
JOIN catalog_status cs
  ON fa.order_number = cs.cs_order_number
ORDER BY fa.avg_catalog_net_paid DESC
LIMIT 100
