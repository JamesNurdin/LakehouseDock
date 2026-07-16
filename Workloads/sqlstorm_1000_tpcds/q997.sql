WITH months AS (
    SELECT d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
    GROUP BY d_year, d_month_seq
),
store_sales_agg AS (
    SELECT ss.ss_store_sk AS s_store_sk,
           d.d_year,
           d.d_month_seq,
           SUM(ss.ss_net_profit) AS total_store_profit,
           SUM(ss.ss_ext_sales_price) AS total_store_sales,
           COUNT(DISTINCT ss.ss_ticket_number) AS store_txns
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT sr.sr_store_sk,
           d.d_year,
           d.d_month_seq,
           SUM(sr.sr_net_loss) AS total_store_loss,
           SUM(sr.sr_return_amt) AS total_store_return_amt,
           COUNT(*) AS return_txns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
),
store_metrics_raw AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_division_id,
        m.d_year,
        m.d_month_seq,
        COALESCE(ssa.total_store_profit, 0) - COALESCE(sra.total_store_loss, 0) AS net_store_profit,
        COALESCE(ssa.total_store_sales, 0) - COALESCE(sra.total_store_return_amt, 0) AS net_store_sales,
        COALESCE(ssa.store_txns, 0) - COALESCE(sra.return_txns, 0) AS net_transactions
    FROM store s
    CROSS JOIN months m
    LEFT JOIN store_sales_agg ssa
        ON s.s_store_sk = ssa.s_store_sk
        AND ssa.d_year = m.d_year
        AND ssa.d_month_seq = m.d_month_seq
    LEFT JOIN store_returns_agg sra
        ON s.s_store_sk = sra.sr_store_sk
        AND sra.d_year = m.d_year
        AND sra.d_month_seq = m.d_month_seq
),
catalog_sales_agg AS (
    SELECT cs.cs_call_center_sk AS cc_call_center_sk,
           d.d_year,
           d.d_month_seq,
           SUM(cs.cs_net_profit) AS total_cc_profit,
           SUM(cs.cs_ext_sales_price) AS total_cc_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_call_center_sk, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT cr.cr_call_center_sk AS cc_call_center_sk,
           d.d_year,
           d.d_month_seq,
           SUM(cr.cr_net_loss) AS total_cc_loss,
           SUM(cr.cr_return_amount) AS total_cc_return_amt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_call_center_sk, d.d_year, d.d_month_seq
),
cc_metrics_raw AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        m.d_year,
        m.d_month_seq,
        COALESCE(cs.total_cc_profit, 0) - COALESCE(cr.total_cc_loss, 0) AS net_cc_profit,
        COALESCE(cs.total_cc_sales, 0) - COALESCE(cr.total_cc_return_amt, 0) AS net_cc_sales
    FROM call_center cc
    CROSS JOIN months m
    LEFT JOIN catalog_sales_agg cs
        ON cc.cc_call_center_sk = cs.cc_call_center_sk
        AND cs.d_year = m.d_year
        AND cs.d_month_seq = m.d_month_seq
    LEFT JOIN catalog_returns_agg cr
        ON cc.cc_call_center_sk = cr.cc_call_center_sk
        AND cr.d_year = m.d_year
        AND cr.d_month_seq = m.d_month_seq
),
store_metrics AS (
    SELECT
        CONCAT(sm.s_store_name, ' (', sm.s_city, ', ', sm.s_state, ')') AS store_full_name,
        sm.s_store_sk,
        sm.s_city,
        sm.s_state,
        sm.s_division_id,
        sm.d_year,
        sm.d_month_seq,
        ROUND(sm.net_store_sales, 2) AS net_store_sales,
        ROUND(sm.net_store_profit, 2) AS net_store_profit,
        sm.net_transactions,
        COALESCE(cc.net_cc_sales, 0) AS net_cc_sales,
        COALESCE(cc.net_cc_profit, 0) AS net_cc_profit,
        RANK() OVER (PARTITION BY sm.d_year, sm.d_month_seq ORDER BY sm.net_store_profit DESC) AS profit_rank,
        SUM(sm.net_store_profit) OVER (PARTITION BY sm.s_store_sk ORDER BY sm.d_year, sm.d_month_seq
                                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        (SELECT AVG(sub.net_store_profit)
         FROM store_metrics_raw sub
         WHERE sub.s_division_id = sm.s_division_id
           AND sub.d_year = sm.d_year
           AND sub.d_month_seq = sm.d_month_seq) AS avg_division_profit
    FROM store_metrics_raw sm
    LEFT JOIN cc_metrics_raw cc
        ON cc.d_year = sm.d_year
       AND cc.d_month_seq = sm.d_month_seq
    WHERE sm.net_store_sales > 0
      AND (sm.s_state IS NOT NULL OR sm.s_city IS NOT NULL)
),
summary AS (
    SELECT
        CAST('ALL STORES' AS varchar) AS store_full_name,
        CAST(NULL AS integer) AS s_store_sk,
        CAST(NULL AS varchar) AS s_city,
        CAST(NULL AS varchar) AS s_state,
        CAST(NULL AS integer) AS s_division_id,
        d_year,
        d_month_seq,
        ROUND(SUM(net_store_sales), 2) AS net_store_sales,
        ROUND(SUM(net_store_profit), 2) AS net_store_profit,
        SUM(net_transactions) AS net_transactions,
        ROUND(SUM(net_cc_sales), 2) AS net_cc_sales,
        ROUND(SUM(net_cc_profit), 2) AS net_cc_profit,
        CAST(NULL AS bigint) AS profit_rank,
        CAST(NULL AS decimal(38,2)) AS cumulative_profit,
        CAST(NULL AS decimal(38,2)) AS avg_division_profit
    FROM store_metrics
    GROUP BY d_year, d_month_seq
)
SELECT *
FROM store_metrics
UNION ALL
SELECT *
FROM summary
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 100
