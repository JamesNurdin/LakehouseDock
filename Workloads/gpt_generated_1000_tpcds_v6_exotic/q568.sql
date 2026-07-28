/*
  Goal: Analyze store return performance by store, year, and return reason, while
  incorporating related web‑return activity, demographic information and address
  diversity. The query produces totals, counts, a net‑loss sum, categorises the
  return amount relative to the overall average, adds subtotal rows via a ROLLUP,
  filters to reasons that also appear in high‑value web returns, and limits the
  output to the top 100 rows.
*/
WITH sr_cte AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
)
SELECT
    st.s_store_name,
    d_ret.d_year,
    r.r_reason_desc,
    SUM(sr_cte.sr_net_loss)                AS total_net_loss,
    COUNT(*)                                 AS return_cnt,
    CASE
        WHEN SUM(sr_cte.sr_return_amt) > (SELECT AVG(sra.sr_return_amt) FROM store_returns sra)
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END                                     AS amt_category,
    (SELECT COUNT(DISTINCT ca_sub.ca_address_sk) FROM customer_address ca_sub) AS distinct_address_cnt
FROM sr_cte
JOIN date_dim d_ret
    ON sr_cte.sr_returned_date_sk = d_ret.d_date_sk                                   -- join 1
JOIN time_dim t_ret
    ON sr_cte.sr_return_time_sk = t_ret.t_time_sk                                      -- join 2
JOIN household_demographics hd_ret
    ON sr_cte.sr_hdemo_sk = hd_ret.hd_demo_sk                                         -- join 3
JOIN customer_address ca_ret
    ON sr_cte.sr_addr_sk = ca_ret.ca_address_sk                                       -- join 4
JOIN store st
    ON sr_cte.sr_store_sk = st.s_store_sk                                            -- join 5
JOIN reason r
    ON sr_cte.sr_reason_sk = r.r_reason_sk                                           -- join 6
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk                                        -- join 7 (via same date dim as store‑returns)
JOIN date_dim d_web
    ON wr.wr_returned_date_sk = d_web.d_date_sk                                        -- join 8 (second alias of date_dim)
JOIN time_dim t_web
    ON wr.wr_returned_time_sk = t_web.t_time_sk                                        -- join 9
JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk                                               -- join 10 (second alias of reason)
JOIN date_dim d_closed
    ON st.s_closed_date_sk = d_closed.d_date_sk                                        -- join 11 (store closed date)
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_reason_sk = r.r_reason_sk
      AND wr2.wr_return_amt > 1000
)
GROUP BY ROLLUP (st.s_store_name, d_ret.d_year, r.r_reason_desc)
HAVING SUM(sr_cte.sr_net_loss) IS NOT NULL
ORDER BY st.s_store_name NULLS LAST,
         d_ret.d_year NULLS LAST,
         r.r_reason_desc NULLS LAST
LIMIT 100
