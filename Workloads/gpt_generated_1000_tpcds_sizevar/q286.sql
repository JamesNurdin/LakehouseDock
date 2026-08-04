WITH
  /* Subquery A – sales joined to store returns and several dimensions */
  subquery_a AS (
    SELECT
      d_sold.d_year                       AS year,
      cc.cc_name                         AS call_center,
      SUM(cs.cs_net_paid)                AS total_net_paid,
      SUM(sr.sr_net_loss)                AS total_store_loss,
      COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    /* core dimensions */
    JOIN date_dim d_sold               ON cs.cs_sold_date_sk      = d_sold.d_date_sk
    JOIN call_center cc                ON cs.cs_call_center_sk    = cc.cc_call_center_sk
    JOIN customer cust                 ON cs.cs_bill_customer_sk  = cust.c_customer_sk
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk   = cp.cp_catalog_page_sk
    JOIN household_demographics hd_cust ON cs.cs_bill_hdemo_sk    = hd_cust.hd_demo_sk
    /* store‑return side */
    JOIN store_returns sr              ON sr.sr_customer_sk       = cust.c_customer_sk
    JOIN date_dim d_ret                ON sr.sr_returned_date_sk  = d_ret.d_date_sk
    JOIN store s                       ON sr.sr_store_sk          = s.s_store_sk
    JOIN date_dim d_store_closed       ON s.s_closed_date_sk      = d_store_closed.d_date_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = cust.c_customer_sk
              AND sr2.sr_returned_date_sk = d_sold.d_date_sk
          )
    GROUP BY d_sold.d_year, cc.cc_name
  ),

  /* Subquery B – sales joined to catalog returns and similar dimensions */
  subquery_b AS (
    SELECT
      d_sold.d_year                       AS year,
      cc.cc_name                         AS call_center,
      SUM(cs.cs_net_paid)                AS total_net_paid,
      SUM(cr.cr_net_loss)                AS total_store_loss,
      COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold               ON cs.cs_sold_date_sk      = d_sold.d_date_sk
    JOIN call_center cc                ON cs.cs_call_center_sk    = cc.cc_call_center_sk
    JOIN customer cust                 ON cs.cs_bill_customer_sk  = cust.c_customer_sk
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk   = cp.cp_catalog_page_sk
    JOIN household_demographics hd_cust ON cs.cs_bill_hdemo_sk    = hd_cust.hd_demo_sk
    /* catalog‑return side */
    JOIN catalog_returns cr            ON cr.cr_order_number      = cs.cs_order_number
    JOIN date_dim d_cr                 ON cr.cr_returned_date_sk  = d_cr.d_date_sk
    JOIN call_center cc2               ON cr.cr_call_center_sk    = cc2.cc_call_center_sk
    JOIN catalog_page cp2              ON cr.cr_catalog_page_sk   = cp2.cp_catalog_page_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_returned_date_sk = d_sold.d_date_sk
          )
    GROUP BY d_sold.d_year, cc.cc_name
  ),

  /* Intersection of the two aggregated result sets */
  intersected AS (
    SELECT * FROM subquery_a
    INTERSECT
    SELECT * FROM subquery_b
  )

SELECT
  ROW_NUMBER() OVER (ORDER BY year, call_center) AS row_num,
  year,
  call_center,
  total_net_paid,
  total_store_loss,
  orders_cnt
FROM intersected
ORDER BY year, call_center
LIMIT 100
