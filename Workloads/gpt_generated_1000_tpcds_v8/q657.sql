WITH
  -- Union of all customers that appear as biller or shipper (deduplicated)
  union_customers AS (
    SELECT cs_bill_customer_sk AS customer_sk FROM tpcds.catalog_sales
    UNION
    SELECT cs_ship_customer_sk FROM tpcds.catalog_sales
  ),

  -- Orders that both have a qualifying return and a high profit sale
  intersect_orders AS (
    SELECT cr_returned_date_sk AS order_number FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_amount > 100
    INTERSECT
    SELECT cs_order_number FROM tpcds.catalog_sales cs
    WHERE cs.cs_net_profit > 50
  )

SELECT
  cs.cs_order_number,
  d_sold.d_date,
  i.i_item_id,
  i.i_category,
  cp.cp_description,
  sm.sm_carrier,
  cd.cd_credit_rating,
  hd.hd_income_band_sk,
  ib.ib_lower_bound,
  cr.cr_return_amount,
  -- Global row number (no partition)
  ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC)               AS global_row_num,
  -- Rank inside each item category by net paid
  RANK() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_paid DESC) AS category_rank,
  -- Number of returns linked to the same order (correlated scalar subquery)
  (SELECT COUNT(*) FROM tpcds.catalog_returns cr2 WHERE cr2.cr_order_number = cs.cs_order_number) AS return_count_for_order,
  -- Average net paid for the same item (scalar subquery)
  (SELECT AVG(cs2.cs_net_paid) FROM tpcds.catalog_sales cs2 WHERE cs2.cs_item_sk = cs.cs_item_sk) AS avg_item_net_paid,
  CASE WHEN cs.cs_net_profit > 100 THEN 'HIGH' ELSE 'LOW' END AS profit_level
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d_sold               ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t                     ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.item i                        ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN tpcds.catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                                           AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN tpcds.reason r                 ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN tpcds.web_page wp              ON wp.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.web_site ws              ON ws.web_open_date_sk = d_sold.d_date_sk
WHERE
  d_sold.d_year = 2001
  AND i.i_current_price > 100
  AND cd.cd_credit_rating = 'High Risk'
  AND t.t_hour BETWEEN 9 AND 17
  AND cp.cp_description LIKE '%store%'
  AND cs.cs_net_paid IS NOT NULL
  AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
  AND cs.cs_bill_customer_sk IN (SELECT customer_sk FROM union_customers)
  AND EXISTS (
        SELECT 1 FROM tpcds.catalog_returns cr3
        WHERE cr3.cr_order_number = cs.cs_order_number
          AND cr3.cr_return_amount > cs.cs_net_paid * 0.1
      )
ORDER BY global_row_num
LIMIT 100
