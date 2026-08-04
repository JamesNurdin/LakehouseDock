/*
  Goal: Analyze catalog return performance by year, market, department and reason, while also breaking down by each word in the call‑center name. The query joins all nine TPC‑DS tables using only the permitted keys, filters on multiple dimensions, expands the call‑center name into words with UNNEST, aggregates twice, and returns the top rows by total return amount.
*/
WITH expanded_cc AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_reason_sk,
        cr.cr_returning_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cp.cp_department,
        cp.cp_type,
        d_ret.d_date,
        d_ret.d_year,
        t.t_hour,
        r.r_reason_desc,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_gmt_offset,
        s.s_market_id,
        s.s_state,
        wp.wp_url,
        wp.wp_type,
        name_part
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd
      ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d_ret.d_date_sk
    CROSS JOIN UNNEST(SPLIT(cc.cc_name, ' ')) AS t(name_part)
    WHERE d_ret.d_year BETWEEN 2000 AND 2002               -- predicate 1
      AND cr.cr_return_quantity > 1                       -- predicate 2
      AND t.t_hour BETWEEN 9 AND 17                       -- predicate 3
      AND s.s_market_id IN (6, 8)                         -- predicate 4
      AND cc.cc_manager = 'John Melendez'                -- predicate 5
      AND r.r_reason_desc LIKE '%warranty%'               -- predicate 6
),
agg AS (
    SELECT
        d_year,
        s_market_id,
        cp_department,
        r_reason_desc,
        name_part,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM expanded_cc
    GROUP BY d_year, s_market_id, cp_department, r_reason_desc, name_part
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    d_year,
    s_market_id,
    cp_department,
    r_reason_desc,
    name_part,
    total_return_amount,
    total_net_loss,
    return_cnt,
    total_net_loss / return_cnt AS avg_loss_per_return
FROM agg
WHERE return_cnt > 5
ORDER BY total_return_amount DESC
LIMIT 100
