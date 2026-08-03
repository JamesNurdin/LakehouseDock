-- Goal: Analyze sales performance by year and category, incorporating inventory levels, return behavior, and demographic factors while demonstrating complex query features (CTE aggregation, FULL OUTER JOIN, EXCEPT, UNION, TABLESAMPLE, and multiple DISTINCT aggregates).
WITH
  -- Aggregate store_sales per item and date (pre‑aggregation CTE)
  sales_agg AS (
    SELECT
      ss_item_sk,
      ss_sold_date_sk,
      ss_store_sk,
      ss_ticket_number,
      SUM(ss_ext_sales_price)   AS total_sales,
      COUNT(DISTINCT ss_customer_sk) AS distinct_customers
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_store_sk, ss_ticket_number
  ),
  -- Sample a fraction of the inventory table (TABLESAMPLE)
  inventory_sample AS (
    SELECT inv_item_sk,
           inv_date_sk,
           inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  -- Basic item reference data
  item_info AS (
    SELECT i_item_sk,
           i_category,
           i_current_price,
           i_product_name
    FROM item
  ),
  -- UNION of distinct return keys from store and web channels (UNION distinct)
  union_returns AS (
    SELECT DISTINCT sr_item_sk  AS item_sk,
                    sr_returned_date_sk AS date_sk
    FROM store_returns
    WHERE sr_return_quantity > 0
    UNION
    SELECT DISTINCT wr_item_sk  AS item_sk,
                    wr_returned_date_sk AS date_sk
    FROM web_returns
    WHERE wr_return_quantity > 0
  ),
  -- Aggregate return amounts per item/date (pre‑aggregation CTE)
  item_return_agg AS (
    SELECT
      item_sk,
      date_sk,
      SUM(return_amount)               AS total_return_amount,
      COUNT(DISTINCT ticket_number)    AS distinct_return_tickets
    FROM (
      SELECT sr_item_sk   AS item_sk,
             sr_returned_date_sk AS date_sk,
             sr_return_amt_inc_tax AS return_amount,
             sr_ticket_number      AS ticket_number
      FROM store_returns
      WHERE sr_return_quantity > 0
      UNION ALL
      SELECT wr_item_sk   AS item_sk,
             wr_returned_date_sk AS date_sk,
             wr_return_amt_inc_tax AS return_amount,
             NULL                AS ticket_number
      FROM web_returns
      WHERE wr_return_quantity > 0
    ) t
    GROUP BY item_sk, date_sk
  ),
  -- Items sold but never appearing in catalog returns (EXCEPT)
  items_not_returned AS (
    SELECT ss_item_sk
    FROM store_sales
    EXCEPT
    SELECT cr_item_sk
    FROM catalog_returns
  )
SELECT
  d.d_year,
  i.i_category,
  SUM(s.total_sales)                                       AS total_sales,
  SUM(DISTINCT inv.inv_quantity_on_hand)                   AS distinct_on_hand,
  COUNT(DISTINCT st.s_store_id)                            AS distinct_stores,
  COUNT(DISTINCT r.r_reason_desc)                         AS distinct_reasons,
  COUNT(DISTINCT ca.ca_city)                              AS distinct_cities,
  AVG(COALESCE(ir.total_return_amount, 0))               AS avg_return_amount,
  SUM(DISTINCT s.distinct_customers)                      AS sum_distinct_customers
FROM item_info i
FULL OUTER JOIN inventory_sample inv
       ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN sales_agg s
       ON s.ss_item_sk = i.i_item_sk
LEFT JOIN date_dim d
       ON COALESCE(s.ss_sold_date_sk, inv.inv_date_sk) = d.d_date_sk
LEFT JOIN store st
       ON s.ss_store_sk = st.s_store_sk
LEFT JOIN store_returns sr
       ON s.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r
       ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN customer_address ca
       ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
       ON sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
       ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
       ON cr.cr_item_sk = i.i_item_sk
      AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w
       ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN reason cr_r
       ON cr.cr_reason_sk = cr_r.r_reason_sk
LEFT JOIN web_returns wr
       ON i.i_item_sk = wr.wr_item_sk
      AND d.d_date_sk = wr.wr_returned_date_sk
LEFT JOIN union_returns ur
       ON i.i_item_sk = ur.item_sk
      AND d.d_date_sk = ur.date_sk
LEFT JOIN item_return_agg ir
       ON i.i_item_sk = ir.item_sk
      AND d.d_date_sk = ir.date_sk
WHERE d.d_year BETWEEN 2000 AND 2002                           -- predicate 1
  AND i.i_current_price > 20                                    -- predicate 2
  AND st.s_state = 'CA'                                          -- predicate 3
  AND ca.ca_country = 'United States'                           -- predicate 4
  AND r.r_reason_id = 'AAAAAAAADBAAAAAA'                         -- predicate 5
  AND cc.cc_gmt_offset BETWEEN -5 AND 5                         -- predicate 6
  AND EXISTS (SELECT 1 FROM items_not_returned innr WHERE innr.ss_item_sk = s.ss_item_sk)
GROUP BY d.d_year, i.i_category
HAVING SUM(s.total_sales) > 20000
ORDER BY d.d_year DESC, total_sales DESC
LIMIT 100
