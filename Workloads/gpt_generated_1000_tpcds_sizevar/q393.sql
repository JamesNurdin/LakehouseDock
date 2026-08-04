/*
  Goal: Identify the highest return amounts per state for the year 2001, combining return, sales, customer, demographic, inventory, store and web page data. The query ranks the results, applies multiple filters, uses a sampled sales CTE, pre‑aggregates inventory, includes a correlated scalar subquery, and filters with an EXISTS clause.
*/
WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
)
SELECT
    cr.cr_returned_date_sk,
    d.d_date,
    ca.ca_city,
    ca.ca_state,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cr.cr_refunded_cash,
    cr.cr_return_amount,
    ss.ss_net_paid,
    wp.wp_url,
    inv_agg.total_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cr.cr_return_amount DESC) AS rn_state,
    RANK() OVER (ORDER BY cr.cr_return_amount DESC) AS overall_rank,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cr.cr_refunded_customer_sk
    ) AS store_sales_cnt_for_customer
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN sampled_sales cs
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inv_agg
  ON inv_agg.inv_date_sk = d.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2001                                 -- filter 1
  AND ca.ca_state IN ('CA', 'TX', 'NY')               -- filter 2
  AND ib.ib_upper_bound >= 50000                      -- filter 3
  AND cr.cr_return_amount > 1000                      -- filter 4
  AND ss.ss_net_paid > 0                              -- filter 5
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = cr.cr_refunded_customer_sk
          AND cr2.cr_return_amount > 2000
      )                                               -- filter 6 (subquery)
ORDER BY overall_rank
LIMIT 100
