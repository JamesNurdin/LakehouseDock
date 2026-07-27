WITH returns_enriched AS (
    SELECT
        wr.wr_returning_customer_sk,
        wr.wr_refunded_cash,
        t.t_sub_shift,
        t.t_shift,
        r.r_reason_desc,
        r.r_reason_id
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE t.t_sub_shift = 'morning'
      AND t.t_shift = 'first'
      AND r.r_reason_desc LIKE '%gift%'
      AND wr.wr_refunded_cash > 200
),
aggregated AS (
    SELECT
        r_reason_desc,
        t_sub_shift,
        t_shift,
        wr_returning_customer_sk,
        SUM(wr_refunded_cash) AS total_refunded_cash
    FROM returns_enriched
    GROUP BY r_reason_desc, t_sub_shift, t_shift, wr_returning_customer_sk
)
SELECT
    a.r_reason_desc,
    a.t_sub_shift,
    a.t_shift,
    a.wr_returning_customer_sk,
    a.total_refunded_cash,
    RANK() OVER (PARTITION BY a.r_reason_desc ORDER BY a.total_refunded_cash DESC) AS rank_by_reason,
    ROW_NUMBER() OVER (PARTITION BY a.t_sub_shift ORDER BY a.total_refunded_cash DESC) AS rownum_by_sub_shift
FROM aggregated a
ORDER BY a.total_refunded_cash DESC
LIMIT 100
