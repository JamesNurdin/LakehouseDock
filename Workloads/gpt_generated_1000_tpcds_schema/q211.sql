/*
Goal: Compute, for each Call Center and Web Site pair, the combined amount of catalog returns and web sales on a specific year, then derive the average total amount per Call Center and filter those pairs whose average exceeds a dynamic threshold. The query demonstrates complex joins across all five tables, multiple filter predicates, a CTE for aggregation, a scalar subquery, an EXISTS filter, and an INTERSECT of two derived result sets.
*/
WITH base AS (
    SELECT
        cc.cc_call_center_id,
        wsit.web_site_id,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(ws.ws_net_paid) AS sum_net_paid
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d_ret.d_year = 2001                     -- filter 1: specific year
      AND wsit.web_county = 'Bronx County'       -- filter 2: specific county
      AND cc.cc_state = 'CA'                      -- filter 3: call center state
    GROUP BY cc.cc_call_center_id, wsit.web_site_id
),
agg AS (
    SELECT
        cc_call_center_id,
        web_site_id,
        sum_return_amount,
        sum_net_paid,
        (sum_return_amount + sum_net_paid) AS total_amount
    FROM base
)
/* First derived set */
SELECT
    t.cc_call_center_id,
    t.web_site_id,
    t.total_amount,
    t.avg_total_across_sites
FROM (
    SELECT
        cc_call_center_id,
        web_site_id,
        total_amount,
        AVG(total_amount) OVER (PARTITION BY cc_call_center_id) AS avg_total_across_sites
    FROM agg
) t
WHERE t.avg_total_across_sites > (
        SELECT AVG(total_amount) * 1.1 FROM agg
    )                                            -- scalar subquery for dynamic threshold
  AND EXISTS (
        SELECT 1
        FROM web_site ws2
        WHERE ws2.web_site_id = t.web_site_id
          AND ws2.web_state = 'CA'
    )                                            -- EXISTS subquery filter
  AND t.cc_call_center_id IN (
        SELECT cc_call_center_id
        FROM call_center
        WHERE cc_company = 1
    )                                            -- additional filter predicate
INTERSECT
/* Second derived set */
SELECT
    t2.cc_call_center_id,
    t2.web_site_id,
    t2.total_amount,
    t2.avg_total_across_sites
FROM (
    SELECT
        cc_call_center_id,
        web_site_id,
        total_amount,
        AVG(total_amount) OVER (PARTITION BY cc_call_center_id) AS avg_total_across_sites
    FROM agg
) t2
WHERE t2.avg_total_across_sites < (
        SELECT AVG(total_amount) FROM agg
    )                                            -- opposite side of the average for intersect logic
ORDER BY avg_total_across_sites DESC
LIMIT 100
