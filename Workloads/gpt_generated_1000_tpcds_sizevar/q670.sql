WITH item_sample AS (
  SELECT i_item_sk, i_category, i_brand, i_current_price
  FROM tpcds.item
  TABLESAMPLE BERNOULLI (10)
),
agg AS (
  SELECT
    i1.i_category,
    i1.i_brand,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    COUNT(DISTINCT c1.c_customer_sk) AS distinct_customers,
    COUNT(DISTINCT hd1.hd_buy_potential) AS distinct_buy_potential,
    SUM(DISTINCT ws.ws_quantity * ws.ws_sales_price) AS distinct_web_sales
  FROM item_sample i1
  JOIN tpcds.store_sales ss ON ss.ss_item_sk = i1.i_item_sk
  JOIN tpcds.customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
  JOIN tpcds.household_demographics hd1 ON c1.c_current_hdemo_sk = hd1.hd_demo_sk
  JOIN tpcds.income_band ib1 ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
  JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN tpcds.item i2 ON sr.sr_item_sk = i2.i_item_sk
  JOIN tpcds.customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
  JOIN tpcds.household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
  JOIN tpcds.web_sales ws ON ws.ws_item_sk = i1.i_item_sk
  JOIN tpcds.item i3 ON ws.ws_item_sk = i3.i_item_sk
  JOIN tpcds.customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN tpcds.household_demographics hd3 ON ws.ws_bill_hdemo_sk = hd3.hd_demo_sk
  JOIN tpcds.customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  JOIN tpcds.household_demographics hd4 ON ws.ws_ship_hdemo_sk = hd4.hd_demo_sk
  LEFT JOIN LATERAL (
    SELECT ws.ws_quantity * ws.ws_sales_price AS ws_line_total
  ) wl ON TRUE
  WHERE ss.ss_item_sk IN (
    SELECT i_item_sk FROM tpcds.item WHERE i_current_price > 100
  )
  GROUP BY i1.i_category, i1.i_brand
)
SELECT
  a.i_category,
  a.i_brand,
  a.store_sales_total,
  a.distinct_customers,
  a.distinct_buy_potential,
  a.distinct_web_sales,
  ROW_NUMBER() OVER (ORDER BY a.store_sales_total DESC) AS rn
FROM agg a
ORDER BY a.store_sales_total DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
