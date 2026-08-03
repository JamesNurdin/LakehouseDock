WITH
  base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_ext_ship_cost,
      ws.ws_quantity,
      ws.ws_web_site_sk,
      cs.web_name,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender,
      ca_bill.ca_state AS bill_state,
      ca_ship.ca_state AS ship_state,
      cr_refunded.cr_return_amount      AS refunded_return_amount,
      cr_returning.cr_return_amount     AS returning_return_amount,
      sr_bill.sr_return_amt_inc_tax      AS bill_store_return_amt,
      sr_ship.sr_return_amt_inc_tax      AS ship_store_return_amt
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site cs
      ON ws.ws_web_site_sk = cs.web_site_sk
    JOIN tpcds.customer_demographics cd_bill
      ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.customer_demographics cd_ship
      ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN tpcds.customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
      ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN tpcds.catalog_returns cr_refunded
      ON cr_refunded.cr_refunded_cdemo_sk = cd_bill.cd_demo_sk
     AND cr_refunded.cr_refunded_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN tpcds.catalog_returns cr_returning
      ON cr_returning.cr_returning_cdemo_sk = cd_ship.cd_demo_sk
     AND cr_returning.cr_returning_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN tpcds.store_returns sr_bill
      ON sr_bill.sr_cdemo_sk = cd_bill.cd_demo_sk
     AND sr_bill.sr_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN tpcds.store_returns sr_ship
      ON sr_ship.sr_cdemo_sk = cd_ship.cd_demo_sk
     AND sr_ship.sr_addr_sk = ca_ship.ca_address_sk
  ),
  aggregated AS (
    SELECT
      web_name,
      CASE WHEN ws_ext_ship_cost > 500 THEN 'HIGH' ELSE 'LOW' END AS ship_cost_category,
      SUM(ws_ext_sales_price)                                 AS total_sales,
      SUM(COALESCE(refunded_return_amount,0) + COALESCE(returning_return_amount,0)) AS total_catalog_return_amount,
      SUM(COALESCE(bill_store_return_amt,0) + COALESCE(ship_store_return_amt,0))    AS total_store_return_amount,
      COUNT(DISTINCT ws_order_number)                         AS order_cnt
    FROM base
    WHERE ws_quantity > 5
    GROUP BY
      web_name,
      CASE WHEN ws_ext_ship_cost > 500 THEN 'HIGH' ELSE 'LOW' END
    UNION DISTINCT
    SELECT
      web_name,
      CASE WHEN ws_ext_ship_cost > 500 THEN 'HIGH' ELSE 'LOW' END AS ship_cost_category,
      SUM(ws_ext_sales_price)                                 AS total_sales,
      SUM(COALESCE(refunded_return_amount,0) + COALESCE(returning_return_amount,0)) AS total_catalog_return_amount,
      SUM(COALESCE(bill_store_return_amt,0) + COALESCE(ship_store_return_amt,0))    AS total_store_return_amount,
      COUNT(DISTINCT ws_order_number)                         AS order_cnt
    FROM base
    WHERE ws_quantity <= 5
    GROUP BY
      web_name,
      CASE WHEN ws_ext_ship_cost > 500 THEN 'HIGH' ELSE 'LOW' END
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
  web_name,
  ship_cost_category,
  total_sales,
  total_catalog_return_amount,
  total_store_return_amount,
  order_cnt
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
