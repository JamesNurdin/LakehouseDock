WITH
  /* Filtered store sales with address attributes */
  filtered_sales AS (
    SELECT
      ss.*,
      ca.ca_state,
      ca.ca_county,
      ca.ca_street_type
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_ext_list_price > 1000                -- predicate 1
      AND ss.ss_sold_date_sk BETWEEN 2452000 AND 2452600   -- predicate 2
      AND ca.ca_state IN ('CA', 'TX', 'NY')               -- predicate 3
      AND ca.ca_street_type = 'Ave'                       -- predicate 4
      AND ca.ca_county LIKE '%County'                     -- predicate 5
      AND ss.ss_customer_sk IN (                           -- IN‑subquery predicate
            SELECT cr_refunded_customer_sk
            FROM tpcds.catalog_returns)
  ),

  /* Filtered catalog returns with address attributes */
  returns_filtered AS (
    SELECT
      cr.*,
      ca.ca_state AS ret_state,
      ca.ca_county AS ret_county
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_quantity > 10               -- predicate 6
      AND cr.cr_store_credit > 100                -- predicate 7
      AND ca.ca_state = 'CA'                     -- predicate 8
      AND cr.cr_return_amount > 0                -- predicate 9
      AND cr.cr_returned_date_sk BETWEEN 2452000 AND 2452600   -- predicate 10
  ),

  /* Aggregate sales per store and address */
  aggregated AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_addr_sk,
      SUM(ss.ss_net_paid) AS store_net_paid,
      COUNT(*) AS sales_cnt,
      MAX(ss.ss_ext_list_price) AS max_ext_list_price
    FROM filtered_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_addr_sk
  ),

  /* Combine aggregates with address and returns */
  final AS (
    SELECT
      a.ss_store_sk,
      a.store_net_paid,
      a.sales_cnt,
      a.max_ext_list_price,
      ca.ca_state,
      rf.cr_return_quantity,
      rf.cr_store_credit,
      ROW_NUMBER() OVER (PARTITION BY a.ss_store_sk ORDER BY a.store_net_paid DESC) AS rn_store,
      CASE
        WHEN rf.cr_store_credit > 500 THEN 'HIGH'
        WHEN rf.cr_store_credit > 200 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS credit_category
    FROM aggregated a
    JOIN tpcds.customer_address ca
      ON a.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN returns_filtered rf
      ON rf.cr_refunded_addr_sk = ca.ca_address_sk
  )

SELECT
  f.ss_store_sk,
  f.store_net_paid,
  f.sales_cnt,
  f.max_ext_list_price,
  f.ca_state,
  f.cr_return_quantity,
  f.cr_store_credit,
  f.credit_category,
  f.rn_store,
  d.dim_label
FROM final f
CROSS JOIN (
  VALUES (1, 'A'), (2, 'B')
) AS d(dim_id, dim_label)
ORDER BY f.store_net_paid DESC, f.rn_store
LIMIT 100
