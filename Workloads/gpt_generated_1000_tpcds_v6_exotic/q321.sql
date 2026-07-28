WITH
  sales_agg AS (
    SELECT
      i.i_category AS category,
      hd.hd_buy_potential AS buy_potential,
      ss.ss_sold_date_sk AS sold_date_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE
      i.i_current_price > 20.00
      AND hd.hd_vehicle_count >= 0
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451210
      AND i.i_category IN ('Electronics', 'Books')
      AND hd.hd_buy_potential <> 'Unknown'
    GROUP BY ROLLUP (i.i_category, hd.hd_buy_potential, ss.ss_sold_date_sk)
  ),
  returns_agg AS (
    SELECT
      i.i_category AS category,
      w.w_state AS state,
      cr.cr_returned_date_sk AS return_date_sk,
      r.r_reason_desc AS reason_desc,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
      cp.cp_catalog_number = 19
      AND cp.cp_catalog_page_number = 5
      AND w.w_state = 'CA'
      AND r.r_reason_desc LIKE '%Defect%'
      AND cr.cr_return_amount > 0
    GROUP BY CUBE (i.i_category, w.w_state, r.r_reason_desc, cr.cr_returned_date_sk)
  ),
  combined AS (
    SELECT
      category,
      buy_potential,
      sold_date_sk,
      total_sales,
      total_profit,
      distinct_tickets,
      NULL AS state,
      NULL AS reason_desc,
      NULL AS return_date_sk,
      NULL AS total_return_amount,
      NULL AS distinct_orders
    FROM sales_agg
    UNION ALL
    SELECT
      category,
      NULL AS buy_potential,
      NULL AS sold_date_sk,
      NULL AS total_sales,
      NULL AS total_profit,
      NULL AS distinct_tickets,
      state,
      reason_desc,
      return_date_sk,
      total_return_amount,
      distinct_orders
    FROM returns_agg
  )
SELECT
  category,
  state,
  AVG(total_sales) AS avg_sales,
  SUM(total_return_amount) AS sum_returns,
  COUNT(DISTINCT purchase_day) AS distinct_sale_days
FROM (
  SELECT
    category,
    state,
    total_sales,
    total_return_amount,
    COALESCE(sold_date_sk, return_date_sk) AS purchase_day
  FROM combined
  WHERE category IS NOT NULL
) c
GROUP BY GROUPING SETS ( (category), (state) )
HAVING
  (category IS NOT NULL AND AVG(total_sales) > 1000)
  OR (state IS NOT NULL AND SUM(total_return_amount) > 500)
ORDER BY
  category ASC NULLS LAST,
  state ASC NULLS LAST
LIMIT 100
