WITH base AS (
   SELECT
     s.s_store_id AS store_id,
     s.s_store_name AS store_name,
     s.s_state AS state,
     d_ret.d_year AS year,
     d_ret.d_month_seq AS month_seq,
     r.r_reason_desc AS reason_desc,
     hd_ref.hd_income_band_sk AS income_band,
     cp.cp_department AS department,
     p.p_purpose AS purpose,
     SUM(wr.wr_return_amt) AS total_return_amt,
     SUM(wr.wr_refunded_cash) AS total_refunded_cash,
     COUNT(*) AS return_cnt
   FROM tpcds.web_returns wr
   JOIN tpcds.date_dim d_ret
     ON wr.wr_returned_date_sk = d_ret.d_date_sk
   JOIN tpcds.time_dim t
     ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN tpcds.household_demographics hd_ref
     ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN tpcds.household_demographics hd_ret
     ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
   JOIN tpcds.reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   JOIN tpcds.web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.date_dim d_wp_create
     ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
   JOIN tpcds.catalog_page cp
     ON cp.cp_start_date_sk = d_ret.d_date_sk
   JOIN tpcds.store s
     ON s.s_closed_date_sk = d_ret.d_date_sk
   JOIN tpcds.promotion p
     ON p.p_start_date_sk = d_ret.d_date_sk
   WHERE d_ret.d_year = 2001
     AND r.r_reason_desc LIKE '%damaged%'
     AND hd_ref.hd_income_band_sk BETWEEN 5 AND 15
     AND s.s_state = 'CA'
     AND t.t_hour BETWEEN 9 AND 17
     AND cp.cp_type = 'Catalog'
   GROUP BY s.s_store_id,
            s.s_store_name,
            s.s_state,
            d_ret.d_year,
            d_ret.d_month_seq,
            r.r_reason_desc,
            hd_ref.hd_income_band_sk,
            cp.cp_department,
            p.p_purpose
)
SELECT
   store_id,
   store_name,
   state,
   year,
   month_seq,
   reason_desc,
   income_band,
   department,
   purpose,
   total_return_amt,
   total_refunded_cash,
   return_cnt,
   total_return_amt / return_cnt AS avg_return_amt
FROM base
WHERE (total_return_amt / return_cnt) > 50
ORDER BY state, year DESC, total_return_amt DESC
LIMIT 100
