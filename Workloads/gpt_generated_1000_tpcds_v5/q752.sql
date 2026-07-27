WITH sold_date AS (
   SELECT d_date_sk,
          d_year
   FROM tpcds.date_dim
),
agg_sales AS (
   SELECT
     d_sold.d_year AS sold_year,
     cc.cc_division_name,
     cd_bill.cd_gender,
     hd_bill.hd_buy_potential,
     COUNT(DISTINCT cs.cs_order_number) AS orders,
     SUM(cs.cs_ext_sales_price) AS total_sales,
     SUM(cs.cs_net_profit) AS total_profit,
     AVG(cs.cs_sales_price) AS avg_sales_price
   FROM tpcds.catalog_sales cs
   INNER JOIN sold_date d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   LEFT OUTER JOIN tpcds.date_dim d_ship
     ON cs.cs_ship_date_sk = d_ship.d_date_sk
   INNER JOIN tpcds.customer_demographics cd_bill
     ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   INNER JOIN tpcds.customer_demographics cd_ship
     ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   INNER JOIN tpcds.household_demographics hd_bill
     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   INNER JOIN tpcds.household_demographics hd_ship
     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT OUTER JOIN tpcds.call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   INNER JOIN tpcds.catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   INNER JOIN tpcds.date_dim d_cc_closed
     ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
   INNER JOIN tpcds.date_dim d_cc_open
     ON cc.cc_open_date_sk = d_cc_open.d_date_sk
   INNER JOIN tpcds.date_dim d_cp_start
     ON cp.cp_start_date_sk = d_cp_start.d_date_sk
   INNER JOIN tpcds.date_dim d_cp_end
     ON cp.cp_end_date_sk = d_cp_end.d_date_sk
   WHERE d_sold.d_year = 2001
     AND cc.cc_division_name IS NOT NULL
   GROUP BY
     d_sold.d_year,
     cc.cc_division_name,
     cd_bill.cd_gender,
     hd_bill.hd_buy_potential
)
SELECT
  sold_year,
  cc_division_name,
  cd_gender,
  hd_buy_potential,
  orders,
  total_sales,
  total_profit,
  avg_sales_price,
  ROW_NUMBER() OVER (PARTITION BY cc_division_name ORDER BY total_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY total_profit DESC
LIMIT 100
