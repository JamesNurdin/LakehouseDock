/*
Goal: Compute, per store and time‑shift, the total catalog sales amount together with the total amount of store returns and web returns, broken down by the reasons for the returns. The query joins all nine selected TPC‑DS tables, re‑uses the time_dim and reason tables under different aliases, and applies a series of explicit joins forming a left‑deep chain.
*/
WITH base AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_sold_time_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_time_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        s.s_store_name,
        r1.r_reason_desc AS store_return_reason,
        wr.wr_return_amt_inc_tax,
        wr.wr_returned_time_sk,
        wr.wr_reason_sk AS web_reason_sk,
        wp.wp_web_page_id,
        r2.r_reason_desc AS web_return_reason,
        t.t_shift
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN store_returns sr
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r1
      ON sr.sr_reason_sk = r1.r_reason_sk
    JOIN web_returns wr
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN time_dim t2
      ON wr.wr_returned_time_sk = t2.t_time_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r2
      ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN customer_demographics cd_refund
      ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund
      ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
)
SELECT
    s_store_name,
    t_shift,
    store_return_reason,
    web_return_reason,
    SUM(cs_ext_sales_price)            AS total_catalog_sales,
    SUM(sr_return_amt_inc_tax)         AS total_store_returns,
    SUM(wr_return_amt_inc_tax)         AS total_web_returns
FROM base
GROUP BY
    s_store_name,
    t_shift,
    store_return_reason,
    web_return_reason
ORDER BY
    total_catalog_sales DESC
LIMIT 100
