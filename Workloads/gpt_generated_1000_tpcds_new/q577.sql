WITH
  -- Store sales joined with returns and reason, applying filters and a row‑number
  sales_returns AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      d.d_year,
      d.d_quarter_seq,
      ss.ss_net_paid_inc_tax,
      sr.sr_return_quantity,
      r.r_reason_desc,
      ROW_NUMBER() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY ss.ss_net_paid_inc_tax DESC) AS rn_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND d.d_weekend = 'N'
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
  ),

  -- Catalog returns joined with call center and warehouse, create an array and unnest it
  catalog_cc_wh AS (
    SELECT
      cr.cr_returned_date_sk,
      d.d_year,
      cc.cc_name,
      w.w_warehouse_name,
      cr.cr_return_amount,
      cr.cr_net_loss,
      ARRAY[cc.cc_state, cc.cc_country] AS cc_location_array,
      loc AS cc_location
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(ARRAY[cc.cc_state, cc.cc_country]) AS t(loc)
    WHERE d.d_year = 2002
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
  ),

  -- Inventory per warehouse and date, aggregated
  inv AS (
    SELECT
      i.inv_date_sk,
      d.d_year,
      i.inv_warehouse_sk,
      w.w_warehouse_name,
      SUM(i.inv_quantity_on_hand) AS total_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
    GROUP BY i.inv_date_sk, d.d_year, i.inv_warehouse_sk, w.w_warehouse_name
  ),

  -- Union of two derived sets to create a distinct key‑metric list
  union_set AS (
    SELECT ss_ticket_number AS key_id, ss_net_paid_inc_tax AS metric
    FROM sales_returns
    WHERE rn_sales = 1
    UNION
    SELECT cr_returned_date_sk AS key_id, cr_return_amount AS metric
    FROM catalog_cc_wh
  ),

  -- Keys that appear in store_sales but not in catalog_returns (EXCEPT)
  key_diff AS (
    SELECT ss_ticket_number AS key_id FROM store_sales
    EXCEPT
    SELECT cr_returned_date_sk AS key_id FROM catalog_returns
  ),

  -- Full outer join of call_center and warehouse to keep all locations
  center_wh_full AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_name,
      w.w_warehouse_id,
      w.w_warehouse_name,
      COALESCE(cc.cc_state, w.w_state) AS state
    FROM call_center cc
    FULL OUTER JOIN warehouse w ON cc.cc_state = w.w_state
  )
SELECT
  us.key_id,
  us.metric,
  ROW_NUMBER() OVER (ORDER BY us.metric DESC) AS overall_rank,
  kd.key_id AS diff_key,
  cwf.cc_call_center_id,
  cwf.w_warehouse_id,
  cwf.state
FROM union_set us
LEFT JOIN key_diff kd ON us.key_id = kd.key_id
LEFT JOIN center_wh_full cwf ON TRUE
WHERE us.metric > 0
ORDER BY overall_rank
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
