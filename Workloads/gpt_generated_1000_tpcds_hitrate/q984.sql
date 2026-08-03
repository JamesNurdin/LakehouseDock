WITH base AS (
        SELECT
            s.s_store_id,
            s.s_state,
            r.r_reason_desc,
            SUM(sr.sr_return_amt_inc_tax) AS store_return_total,
            COUNT(*) AS store_return_cnt,
            SUM(CASE WHEN sr.sr_refunded_cash > 100 THEN sr.sr_refunded_cash ELSE 0 END) AS high_refund_cash,
            SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
            COUNT(wr.wr_order_number) AS web_return_cnt
        FROM store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
        JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
        WHERE s.s_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
          AND s.s_number_employees BETWEEN 50 AND 500
          AND s.s_floor_space > 1000
          AND r.r_reason_desc LIKE '%defect%'
          AND sr.sr_return_amt_inc_tax > 100
          AND wr.wr_return_amt_inc_tax < 500
        GROUP BY s.s_store_id, s.s_state, r.r_reason_desc
    ),
    agg AS (
        SELECT
            b.s_state,
            COUNT(*) AS store_cnt,
            SUM(b.store_return_total) AS total_store_return,
            SUM(b.web_return_total) AS total_web_return,
            AVG(b.store_return_total) AS avg_store_return
        FROM base b
        GROUP BY b.s_state
    )
SELECT
    a.s_state,
    a.store_cnt,
    a.total_store_return,
    a.total_web_return,
    a.avg_store_return,
    CASE WHEN a.total_store_return > a.total_web_return THEN 'StoreHigher' ELSE 'WebHigher' END AS higher_source,
    ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.total_store_return DESC) AS rn,
    d.report_type
FROM agg a
CROSS JOIN (
    SELECT 'All_Stores' AS report_type UNION ALL SELECT 'Filtered_Stores' AS report_type
) d
WHERE EXISTS (
    SELECT 1
    FROM base b
    WHERE b.s_state = a.s_state
      AND b.store_return_total > 200
)
ORDER BY a.total_store_return DESC
LIMIT 100
