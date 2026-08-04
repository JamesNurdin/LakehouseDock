WITH catalog AS (
    SELECT
        td.t_hour AS hour,
        CASE WHEN cr.cr_return_amt_inc_tax > 1000 THEN 'High' ELSE 'Low' END AS return_category,
        ARRAY[cr.cr_return_amt_inc_tax, cr.cr_refunded_cash] AS return_vals
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_amt_inc_tax IS NOT NULL
),
catalog_unnested AS (
    SELECT
        c.hour,
        c.return_category,
        u.ret_val AS return_component
    FROM catalog c
    CROSS JOIN UNNEST(c.return_vals) AS u(ret_val)
),
web AS (
    SELECT
        td.t_hour AS hour,
        CASE WHEN wr.wr_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_category,
        ARRAY[wr.wr_return_amt, wr.wr_refunded_cash] AS return_vals
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_return_amt IS NOT NULL
),
web_unnested AS (
    SELECT
        w.hour,
        w.return_category,
        u.ret_val AS return_component
    FROM web w
    CROSS JOIN UNNEST(w.return_vals) AS u(ret_val)
)
SELECT
    combined.hour,
    combined.return_category,
    SUM(combined.return_component) AS total_return_amount
FROM (
    SELECT hour, return_category, return_component FROM catalog_unnested
    UNION ALL
    SELECT hour, return_category, return_component FROM web_unnested
) AS combined
GROUP BY combined.hour, combined.return_category
ORDER BY combined.hour, total_return_amount DESC
LIMIT 100
