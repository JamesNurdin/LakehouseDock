WITH
  ws_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_quantity,
      ws.ws_net_profit,
      i.i_item_id,
      i.i_current_price,
      i.i_brand,
      c.c_customer_id,
      c.c_birth_year,
      cd.cd_marital_status,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      wp.wp_web_page_id,
      NULL AS cc_company_name   -- placeholder, call_center not linked directly from web_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_current_price > 50
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cd.cd_marital_status IN ('M', 'S')
      AND hd.hd_vehicle_count >= 0
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
  ),
  cr_base AS (
    SELECT
      cr.cr_order_number,
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i.i_item_id,
      c.c_customer_id,
      cd.cd_marital_status,
      hd.hd_vehicle_count,
      cc.cc_company_name,
      cp.cp_department
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cr.cr_return_amount > 0
      AND hd.hd_vehicle_count <> -1
      AND cd.cd_dep_count >= 2
      AND cp.cp_department LIKE 'Electronics%'
      AND cc.cc_company_name LIKE '%anti%'
  ),
  full_join AS (
    SELECT
      ws.ws_order_number,
      ws.i_item_id,
      ws.i_current_price,
      ws.c_customer_id,
      ws.ws_net_profit,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cc_company_name AS cr_cc_company_name,
      ws.cc_company_name AS ws_cc_company_name,
      ROW_NUMBER() OVER (PARTITION BY ws.c_customer_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
      ws.ws_item_sk,
      cr.cr_item_sk
    FROM ws_base ws
    FULL OUTER JOIN cr_base cr
      ON ws.ws_item_sk = cr.cr_item_sk
  ),
  anti_joined AS (
    SELECT *
    FROM full_join f
    WHERE NOT EXISTS (
      SELECT 1
      FROM tpcds.catalog_returns cr2
      WHERE cr2.cr_order_number = f.ws_order_number
    )
  ),
  sold_items AS (
    SELECT i.i_item_id
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
  ),
  returned_items AS (
    SELECT i.i_item_id
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
  ),
  not_returned_items AS (
    SELECT si.i_item_id
    FROM sold_items si
    EXCEPT
    SELECT ri.i_item_id
    FROM returned_items ri
  )
SELECT
  aj.ws_order_number,
  aj.i_item_id,
  aj.i_current_price,
  aj.c_customer_id,
  aj.ws_net_profit,
  aj.profit_rank,
  CASE WHEN aj.cr_return_quantity IS NULL THEN 'NotReturned' ELSE 'Returned' END AS return_status,
  COALESCE(aj.ws_cc_company_name, aj.cr_cc_company_name) AS call_center_company,
  nr.i_item_id AS not_returned_item_id
FROM anti_joined aj
LEFT JOIN not_returned_items nr ON aj.i_item_id = nr.i_item_id
ORDER BY aj.ws_net_profit DESC
LIMIT 100
