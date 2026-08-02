WITH
store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        d_sr.d_year,
        d_sr.d_month_seq,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        MIN(sr.sr_return_time_sk) AS any_return_time_sk,
        MIN(sr.sr_customer_sk) AS any_customer_sk
    FROM store_returns sr
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk, d_sr.d_year, d_sr.d_month_seq
),

distinct_reason AS (
    SELECT DISTINCT r_reason_sk, r_reason_desc
    FROM reason
),

catalog_return_agg AS (
    SELECT
        cr.cr_reason_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        d_cr.d_year,
        d_cr.d_month_seq,
        SUM(cr.cr_return_amount) AS catalog_return_amt,
        SUM(cr.cr_return_quantity) AS catalog_return_qty
    FROM catalog_returns cr
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    GROUP BY cr.cr_reason_sk, cr.cr_call_center_sk, cr.cr_catalog_page_sk, d_cr.d_year, d_cr.d_month_seq
)
SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    r.r_reason_desc AS return_reason,
    agg.d_year,
    agg.d_month_seq,
    agg.store_net_loss,
    cat.catalog_return_amt,
    cat.catalog_return_qty,
    cc.cc_name AS call_center_name,
    cp.cp_description AS catalog_page_desc,
    SUM(agg.store_net_loss) OVER (PARTITION BY s.s_store_id ORDER BY agg.d_year, agg.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_net_loss,
    RANK() OVER (ORDER BY agg.store_net_loss DESC) AS store_net_loss_rank
FROM store_return_agg agg
JOIN store s
    ON agg.sr_store_sk = s.s_store_sk
JOIN distinct_reason r
    ON agg.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_return_agg cat
    ON cat.cr_reason_sk = r.r_reason_sk
    AND cat.d_year = agg.d_year
    AND cat.d_month_seq = agg.d_month_seq
JOIN time_dim t
    ON agg.any_return_time_sk = t.t_time_sk
LEFT JOIN call_center cc
    ON cat.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON cat.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
    ON agg.any_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_store_cl
    ON s.s_closed_date_sk = d_store_cl.d_date_sk
LEFT JOIN date_dim d_cc_cl
    ON cc.cc_closed_date_sk = d_cc_cl.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE wr.wr_reason_sk = r.r_reason_sk
      AND d_wr.d_year = agg.d_year
      AND d_wr.d_month_seq = agg.d_month_seq
)
ORDER BY agg.store_net_loss DESC
LIMIT 100
