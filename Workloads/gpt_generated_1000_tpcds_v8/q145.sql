/*
Goal: Analyze combined catalog and store returns by reason, store, call center, and time, using deep joins across all selected tables, pre‑aggregating returns, re‑using date and demographic dimensions under multiple aliases, and including a scalar subquery for average return amount per reason.
*/
WITH
  /* Aggregate catalog returns by the keys needed for the joins */
  cr_agg AS (
    SELECT
      cr_catalog_page_sk,
      cr_returned_date_sk,
      cr_call_center_sk,
      cr_reason_sk,
      cr_refunded_hdemo_sk,
      cr_returning_hdemo_sk,
      SUM(cr_return_amount)        AS total_return_amount,
      SUM(cr_net_loss)             AS total_net_loss,
      COUNT(*)                     AS cnt_returns
    FROM catalog_returns
    GROUP BY
      cr_catalog_page_sk,
      cr_returned_date_sk,
      cr_call_center_sk,
      cr_reason_sk,
      cr_refunded_hdemo_sk,
      cr_returning_hdemo_sk
  ),
  /* Aggregate store returns by the keys needed for the joins */
  sr_agg AS (
    SELECT
      sr_store_sk,
      sr_returned_date_sk,
      sr_hdemo_sk,
      sr_reason_sk,
      SUM(sr_return_amt)   AS total_store_return_amt,
      SUM(sr_net_loss)     AS total_store_net_loss,
      COUNT(*)             AS cnt_store_returns
    FROM store_returns
    GROUP BY
      sr_store_sk,
      sr_returned_date_sk,
      sr_hdemo_sk,
      sr_reason_sk
  )
SELECT
  d_cr_returned.d_year,
  d_cr_returned.d_month_seq,
  s.s_store_name,
  cc.cc_name                         AS call_center_name,
  cp.cp_description                  AS catalog_page_desc,
  r_cat.r_reason_desc                AS catalog_reason_desc,
  r_store.r_reason_desc              AS store_reason_desc,
  cr_agg.total_return_amount,
  sr_agg.total_store_return_amt,
  (cr_agg.total_net_loss + sr_agg.total_store_net_loss) AS combined_net_loss,
  (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
    WHERE cr2.cr_reason_sk = r_cat.r_reason_sk)                     AS avg_return_amount_for_reason
FROM cr_agg
/* Join catalog side dimensions */
JOIN catalog_page cp
  ON cr_agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
  ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r_cat
  ON cr_agg.cr_reason_sk = r_cat.r_reason_sk
JOIN date_dim d_cr_returned
  ON cr_agg.cr_returned_date_sk = d_cr_returned.d_date_sk
JOIN household_demographics hd_refunded
  ON cr_agg.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
  ON cr_agg.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
/* Join store side aggregations and dimensions */
JOIN sr_agg
  ON TRUE
JOIN store s
  ON sr_agg.sr_store_sk = s.s_store_sk
JOIN reason r_store
  ON sr_agg.sr_reason_sk = r_store.r_reason_sk
JOIN date_dim d_sr_returned
  ON sr_agg.sr_returned_date_sk = d_sr_returned.d_date_sk
JOIN household_demographics hd_store
  ON sr_agg.sr_hdemo_sk = hd_store.hd_demo_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
/* Join call‑center date dimensions (open / closed) */
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
