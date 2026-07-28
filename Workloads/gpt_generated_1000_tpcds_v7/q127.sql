WITH per_customer AS (
    SELECT
        c.c_customer_id,
        cd.cd_marital_status,
        cc.cc_state,
        sm.sm_type,
        w.w_state AS warehouse_state,
        r.r_reason_desc,
        wp.wp_type,
        SUM(cr.cr_return_amount) AS cat_return_sum,
        SUM(wr.wr_return_amt) AS web_return_sum,
        COUNT(*) FILTER (WHERE cr.cr_return_amount IS NOT NULL) AS cat_return_cnt,
        COUNT(*) FILTER (WHERE wr.wr_return_amt IS NOT NULL) AS web_return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND cd.cd_marital_status = 'M'
      AND r.r_reason_desc LIKE '%damaged%'
      AND wp.wp_type = 'NORMAL'
      AND cr.cr_return_amount > 100
      AND wr.wr_return_amt > 50
    GROUP BY
        c.c_customer_id,
        cd.cd_marital_status,
        cc.cc_state,
        sm.sm_type,
        w.w_state,
        r.r_reason_desc,
        wp.wp_type
)
SELECT
    AVG(cat_return_sum + web_return_sum) AS avg_total_return_amount,
    SUM(cat_return_cnt) AS total_catalog_returns,
    SUM(web_return_cnt) AS total_web_returns
FROM per_customer
WHERE (cat_return_sum + web_return_sum) > 500
HAVING COUNT(*) > 10
LIMIT 100
