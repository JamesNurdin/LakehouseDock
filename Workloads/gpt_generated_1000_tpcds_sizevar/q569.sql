WITH
  /* Store returns aggregated by ticket and month */
  store_ret AS (
    SELECT
      sr.sr_ticket_number AS return_key,
      SUM(sr.sr_return_amt_inc_tax) AS total_return,
      DATE_TRUNC('month', d.d_date) AS month_dt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY sr.sr_ticket_number, DATE_TRUNC('month', d.d_date)
  ),

  /* Catalog returns aggregated by order and month */
  catalog_ret AS (
    SELECT
      cr.cr_order_number AS return_key,
      SUM(cr.cr_return_amt_inc_tax) AS total_return,
      DATE_TRUNC('month', d.d_date) AS month_dt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2022
      AND cc.cc_state = 'CA'
    GROUP BY cr.cr_order_number, DATE_TRUNC('month', d.d_date)
  ),

  /* Web returns aggregated by order and month */
  web_ret AS (
    SELECT
      wr.wr_order_number AS return_key,
      SUM(wr.wr_return_amt_inc_tax) AS total_return,
      DATE_TRUNC('month', d.d_date) AS month_dt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2022
      AND wp.wp_type = 'product'
    GROUP BY wr.wr_order_number, DATE_TRUNC('month', d.d_date)
  ),

  /* Keys that should be excluded (high fee store returns) */
  blacklist_keys AS (
    SELECT sr.sr_ticket_number AS return_key
    FROM store_returns sr
    WHERE sr.sr_fee > 100
  ),

  /* Low‑fee store returns that will be subtracted via EXCEPT */
  low_fee_store AS (
    SELECT
      sr.sr_ticket_number AS return_key,
      SUM(sr.sr_return_amt_inc_tax) AS total_return,
      DATE_TRUNC('month', d.d_date) AS month_dt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_fee < 20
    GROUP BY sr.sr_ticket_number, DATE_TRUNC('month', d.d_date)
  ),

  /* Union of store and catalog returns (distinct) */
  union_set AS (
    SELECT return_key, total_return, month_dt FROM store_ret
    UNION
    SELECT return_key, total_return, month_dt FROM catalog_ret
  ),

  /* Intersection with web returns */
  intersect_set AS (
    SELECT u.return_key, u.total_return, u.month_dt
    FROM union_set u
    INTERSECT
    SELECT w.return_key, w.total_return, w.month_dt
    FROM web_ret w
  ),

  /* Subtract low‑fee store keys (EXCEPT) */
  except_set AS (
    SELECT i.return_key, i.total_return, i.month_dt
    FROM intersect_set i
    EXCEPT
    SELECT l.return_key, l.total_return, l.month_dt
    FROM low_fee_store l
  ),

  /* Apply anti‑semi‑join (NOT IN blacklist) */
  filtered_set AS (
    SELECT e.return_key, e.total_return, e.month_dt
    FROM except_set e
    WHERE e.return_key NOT IN (SELECT b.return_key FROM blacklist_keys b)
  ),

  /* Expand an array of month numbers with UNNEST */
  month_numbers AS (
    SELECT month_val
    FROM UNNEST(ARRAY[1,2,3,4,5,6,7,8,9,10,11,12]) AS t(month_val)
  ),

  /* Join the filtered results to the exploded month list */
  final_join AS (
    SELECT f.return_key,
           f.total_return,
           f.month_dt,
           m.month_val
    FROM filtered_set f
    JOIN month_numbers m
      ON EXTRACT(MONTH FROM f.month_dt) = m.month_val
  )
SELECT
  return_key,
  total_return,
  month_dt,
  month_val
FROM final_join
ORDER BY total_return DESC
LIMIT 100
