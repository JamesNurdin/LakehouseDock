WITH
    catalog_returns_agg AS (
        SELECT
            cr.cr_returned_date_sk AS d_date_sk,
            SUM(cr.cr_net_loss) AS total_catalog_net_loss,
            SUM(cr.cr_fee) AS total_catalog_fee,
            SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return_amt_inc_tax
        FROM catalog_returns cr
        GROUP BY cr.cr_returned_date_sk
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_sold_date_sk AS d_date_sk,
            ss.ss_store_sk AS s_store_sk,
            SUM(ss.ss_net_profit) AS total_sales_net_profit,
            SUM(ss.ss_quantity) AS total_sales_quantity,
            SUM(ss.ss_ext_discount_amt) AS total_sales_discount,
            SUM(ss.ss_net_paid_inc_tax) AS total_sales_net_paid_inc_tax
        FROM store_sales ss
        GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk
    ),
    store_returns_agg AS (
        SELECT
            sr.sr_returned_date_sk AS d_date_sk,
            sr.sr_store_sk AS s_store_sk,
            SUM(sr.sr_net_loss) AS total_return_net_loss,
            SUM(sr.sr_return_quantity) AS total_return_quantity,
            SUM(sr.sr_fee) AS total_return_fee,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax
        FROM store_returns sr
        GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk
    ),
    matched_returns AS (
        SELECT
            ss.ss_sold_date_sk AS d_date_sk,
            ss.ss_store_sk AS s_store_sk,
            COUNT(*) AS matched_return_count,
            SUM(sr.sr_return_quantity) AS matched_return_quantity,
            SUM(sr.sr_net_loss) AS matched_return_net_loss
        FROM store_sales ss
        JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    COALESCE(ssa.total_sales_net_profit, 0) AS total_sales_net_profit,
    COALESCE(sra.total_return_net_loss, 0) AS total_return_net_loss,
    COALESCE(cra.total_catalog_net_loss, 0) AS total_catalog_net_loss,
    COALESCE(ssa.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sra.total_return_quantity, 0) AS total_return_quantity,
    CASE
        WHEN COALESCE(ssa.total_sales_quantity, 0) > 0
        THEN COALESCE(sra.total_return_quantity, 0) * 100.0 / ssa.total_sales_quantity
        ELSE NULL
    END AS return_rate_percent,
    CASE
        WHEN COALESCE(ssa.total_sales_quantity, 0) > 0
        THEN ssa.total_sales_discount / ssa.total_sales_quantity
        ELSE NULL
    END AS avg_discount_per_item,
    COALESCE(cra.total_catalog_fee, 0) AS total_catalog_fee,
    COALESCE(sra.total_return_fee, 0) AS total_return_fee,
    COALESCE(mr.matched_return_count, 0) AS matched_return_count,
    COALESCE(mr.matched_return_quantity, 0) AS matched_return_quantity,
    COALESCE(mr.matched_return_net_loss, 0) AS matched_return_net_loss,
    (COALESCE(ssa.total_sales_net_paid_inc_tax, 0)
     - COALESCE(sra.total_return_amt_inc_tax, 0)
     - COALESCE(cra.total_catalog_return_amt_inc_tax, 0)) AS net_income_after_all_returns
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN store_sales_agg ssa
    ON ssa.d_date_sk = d.d_date_sk
    AND ssa.s_store_sk = s.s_store_sk
LEFT JOIN store_returns_agg sra
    ON sra.d_date_sk = d.d_date_sk
    AND sra.s_store_sk = s.s_store_sk
LEFT JOIN catalog_returns_agg cra
    ON cra.d_date_sk = d.d_date_sk
LEFT JOIN matched_returns mr
    ON mr.d_date_sk = d.d_date_sk
    AND mr.s_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1999 AND 2001
ORDER BY total_sales_net_profit DESC
LIMIT 100
