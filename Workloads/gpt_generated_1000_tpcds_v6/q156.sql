WITH joined AS (
    SELECT
        s.s_division_id,
        s.s_store_name,
        r.r_reason_desc,
        t.t_hour,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        cc.cc_market_manager,
        cd.cd_credit_rating,
        cp.cp_department,
        wp.wp_type
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND cc.cc_market_manager = 'John Doe'
      AND cd.cd_credit_rating = 'High Risk'
),
aggregated AS (
    SELECT
        s_division_id,
        r_reason_desc,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(sr_net_loss) AS total_store_return_loss,
        COUNT(DISTINCT cp_department) AS distinct_departments
    FROM joined
    GROUP BY GROUPING SETS (
        (s_division_id, r_reason_desc),
        (s_division_id),
        (r_reason_desc)
    )
)
SELECT
    s_division_id,
    r_reason_desc,
    total_catalog_profit,
    total_web_profit,
    total_store_return_loss,
    distinct_departments,
    RANK() OVER (ORDER BY total_catalog_profit DESC) AS catalog_profit_rank,
    AVG(total_catalog_profit) OVER (PARTITION BY s_division_id) AS avg_catalog_profit_by_div,
    (SELECT DISTINCT r2.r_reason_desc FROM reason r2 WHERE r2.r_reason_desc LIKE '%damaged%' LIMIT 1) AS sample_reason_desc
FROM aggregated
WHERE total_catalog_profit IS NOT NULL
ORDER BY catalog_profit_rank
LIMIT 100
