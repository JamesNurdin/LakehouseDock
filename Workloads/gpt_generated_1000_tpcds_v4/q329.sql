WITH filtered_data AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_mkt_id,
        cc.cc_company,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        c.c_customer_id,
        c.c_last_review_date,
        wp.wp_web_page_id,
        wp.wp_type,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE cc.cc_mkt_id = 5
      AND cc.cc_company = 3
      AND w.w_warehouse_sk = 7
      AND c.c_last_review_date = 2452573
)
SELECT
    cc_call_center_id,
    cc_name,
    w_warehouse_id,
    w_city,
    wp_type,
    COUNT(*) AS total_returns,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    AVG(cr_net_loss) AS avg_catalog_net_loss,
    AVG(wr_net_loss) AS avg_web_net_loss,
    MIN(cr_return_amount) AS min_catalog_return_amount,
    MAX(wr_return_amt) AS max_web_return_amount
FROM filtered_data
GROUP BY
    cc_call_center_id,
    cc_name,
    w_warehouse_id,
    w_city,
    wp_type
ORDER BY total_returns DESC
LIMIT 100
