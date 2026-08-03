WITH
  /* Customers with store sales in 2002 Q1 */
  store_purchasers AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           SUM(ss.ss_net_paid) AS total_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_quarter_seq = 1
    GROUP BY ss.ss_customer_sk
  ),

  /* Customers with web sales in 2002 Q1 */
  web_purchasers AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           SUM(ws.ws_net_paid) AS total_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_quarter_seq = 1
    GROUP BY ws.ws_bill_customer_sk
  ),

  /* Customers who bought both store and web */
  store_web_common AS (
    SELECT cust_sk FROM store_purchasers
    INTERSECT
    SELECT cust_sk FROM web_purchasers
  ),

  /* Customers who bought catalog but not store */
  catalog_only AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    EXCEPT
    SELECT cust_sk FROM store_purchasers
  ),

  /* Union of store purchasers and catalog‑only customers */
  union_customers AS (
    SELECT cust_sk FROM store_purchasers
    UNION
    SELECT cust_sk FROM catalog_only
  ),

  /* Final aggregated view that touches all 15 tables */
  final_agg AS (
    SELECT
      d.d_year,
      ca.ca_state,
      ib.ib_income_band_sk,
      COUNT(DISTINCT cs.cs_order_number)                     AS catalog_orders,
      SUM(cs.cs_ext_sales_price)                               AS catalog_sales,
      SUM(ws.ws_ext_sales_price)                               AS web_sales,
      SUM(ss.ss_ext_sales_price)                               AS store_sales,
      SUM(sr.sr_return_amt)                                    AS total_store_returns,
      AVG(cs.cs_ext_discount_amt)                              AS avg_catalog_discount,
      MIN(ws.ws_net_paid)                                      AS min_web_net_paid,
      MAX(ss.ss_net_paid)                                      AS max_store_net_paid
    FROM catalog_sales cs
    JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca            ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t                     ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss                 ON ss.ss_customer_sk = c.c_customer_sk
                                            AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_sales ws                  ON ws.ws_bill_customer_sk = c.c_customer_sk
                                            AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN store_returns sr               ON sr.sr_customer_sk = c.c_customer_sk
                                            AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r                       ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr                ON wr.wr_refunded_customer_sk = c.c_customer_sk
                                            AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp                    ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE d.d_year = 2002
      AND ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND t.t_hour BETWEEN 8 AND 12
      AND r.r_reason_desc = 'Damaged'
      AND wp.wp_url LIKE 'http://www.%'
      AND cs.cs_quantity > 1
      AND ss.ss_quantity > 0
      AND sr.sr_customer_sk IN (
            SELECT c2.c_customer_sk
            FROM customer c2
            WHERE c2.c_preferred_cust_flag = 'Y'
          )
    GROUP BY d.d_year, ca.ca_state, ib.ib_income_band_sk
  )
SELECT
  f.d_year,
  f.ca_state,
  f.ib_income_band_sk,
  f.catalog_orders,
  f.catalog_sales,
  f.web_sales,
  f.store_sales,
  f.total_store_returns,
  f.avg_catalog_discount,
  f.min_web_net_paid,
  f.max_store_net_paid,
  COUNT(DISTINCT swc.cust_sk) AS common_store_web_customers,
  COUNT(DISTINCT co.cust_sk)   AS catalog_only_customers,
  COUNT(DISTINCT uc.cust_sk)   AS union_customers_total
FROM final_agg f
LEFT JOIN store_web_common swc ON TRUE
LEFT JOIN catalog_only co      ON TRUE
LEFT JOIN union_customers uc   ON TRUE
GROUP BY f.d_year, f.ca_state, f.ib_income_band_sk,
         f.catalog_orders, f.catalog_sales, f.web_sales, f.store_sales,
         f.total_store_returns, f.avg_catalog_discount,
         f.min_web_net_paid, f.max_store_net_paid
