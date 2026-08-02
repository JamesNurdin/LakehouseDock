WITH
  cte_sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      CASE
        WHEN ss.ss_net_profit > 1000 THEN 'High'
        WHEN ss.ss_net_profit > 0  THEN 'Medium'
        ELSE 'Low'
      END AS profit_category
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
  ),
  agg AS (
    SELECT
      d.d_year,
      s.s_store_sk,
      s.s_store_name,
      i.i_brand,
      i.i_category,
      ss.profit_category,
      COUNT(DISTINCT cs.cs_order_number)               AS distinct_orders,
      COUNT(DISTINCT sr.sr_return_quantity)           AS distinct_return_quantities,
      SUM(cs.cs_ext_sales_price)                     AS total_catalog_sales,
      SUM(ss.ss_ext_sales_price)                     AS total_store_sales,
      SUM(sr.sr_net_loss)                            AS total_return_loss,
      COUNT(DISTINCT c_bill.c_customer_sk)           AS distinct_bill_customers,
      COUNT(DISTINCT c_ship.c_customer_sk)           AS distinct_ship_customers,
      (SELECT max(ib_upper_bound) FROM income_band) AS max_income_band
    FROM cte_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer c_bill
      ON ss.ss_customer_sk = c_bill.c_customer_sk
    LEFT JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = d.d_date_sk
         AND cs.cs_item_sk = i.i_item_sk
         AND cs.cs_bill_customer_sk = c_bill.c_customer_sk
    LEFT JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN customer c_ship
      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    WHERE d.d_year = 2000
    GROUP BY
      d.d_year,
      s.s_store_sk,
      s.s_store_name,
      i.i_brand,
      i.i_category,
      ss.profit_category
    HAVING SUM(ss.ss_ext_sales_price) > 10000
  )
SELECT
  d_year,
  s_store_name,
  i_brand,
  i_category,
  profit_category,
  distinct_orders,
  distinct_return_quantities,
  total_catalog_sales,
  total_store_sales,
  total_return_loss,
  distinct_bill_customers,
  distinct_ship_customers,
  max_income_band,
  ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY total_store_sales DESC) AS store_sales_rank
FROM agg
ORDER BY total_store_sales DESC
LIMIT 100
