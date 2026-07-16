WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cc.cc_state AS region,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_employees > 3000000
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY r.r_reason_desc, cc.cc_state
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        wp.wp_type AS region,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wp.wp_rec_start_date >= DATE '2000-01-01'
    GROUP BY r.r_reason_desc, wp.wp_type
)
SELECT
    COALESCE(ca.reason_desc, wa.reason_desc) AS reason_desc,
    COALESCE(ca.region, wa.region) AS region,
    COALESCE(ca.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(wa.web_net_loss, 0) AS web_net_loss,
    (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    (COALESCE(ca.catalog_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0)) AS total_return_cnt,
    RANK() OVER (ORDER BY (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC) AS loss_rank
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
    ON ca.reason_desc = wa.reason_desc
    AND ca.region = wa.region
WHERE (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) > 10000
ORDER BY total_net_loss DESC
LIMIT 10
