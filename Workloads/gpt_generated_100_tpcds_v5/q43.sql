/*
Goal: Summarize web return amounts by year and state, showing total and average returns, the number of distinct return reasons, and compare each year‑state total against the average total for that year. The query applies several filters, uses a scalar subquery, an EXISTS filter, DISTINCT counts, and orders the result.
*/
WITH per_state_year AS (
    SELECT
        dd.d_year,
        rs.r_reason_desc,
        st.s_state,
        SUM(wr.wr_return_amt)               AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number)  AS distinct_orders,
        AVG(wr.wr_return_quantity)          AS avg_return_qty
    FROM web_returns wr
    JOIN date_dim dd   ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN reason   rs   ON wr.wr_reason_sk      = rs.r_reason_sk
    JOIN store    st   ON st.s_closed_date_sk  = dd.d_date_sk
    WHERE dd.d_weekend = 'N'
      AND dd.d_quarter_seq IN (9, 11, 16)
      AND wr.wr_return_amt > 0
    GROUP BY dd.d_year, rs.r_reason_desc, st.s_state
)
SELECT
    prs.d_year,
    prs.s_state,
    SUM(prs.total_return_amt)                     AS year_state_total_return,
    AVG(prs.total_return_amt)                     AS avg_return_per_reason,
    COUNT(DISTINCT prs.r_reason_desc)            AS distinct_reason_cnt,
    (
        SELECT COUNT(DISTINCT r2.r_reason_desc)
        FROM reason r2
        WHERE r2.r_reason_desc LIKE '%purchase%'
    )                                             AS purchase_reason_total
FROM per_state_year prs
WHERE NOT EXISTS (
    SELECT 1
    FROM reason r_ex
    WHERE r_ex.r_reason_desc = prs.r_reason_desc
      AND r_ex.r_reason_desc LIKE '%size%'
)
GROUP BY prs.d_year, prs.s_state
HAVING SUM(prs.total_return_amt) > (
    SELECT AVG(inner_prs.total_return_amt)
    FROM per_state_year inner_prs
    WHERE inner_prs.d_year = prs.d_year
)
ORDER BY year_state_total_return DESC
LIMIT 100
