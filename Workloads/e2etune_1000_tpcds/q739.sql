WITH returns AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_refunded_customer_sk,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450365
      AND cr.cr_return_amount > 0
),
customer_counts AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt
    FROM customer c
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS shipping_type,
        r.r_reason_desc AS return_reason,
        SUM(rtn.cr_return_amount) AS total_return_amount,
        SUM(rtn.cr_net_loss) AS total_net_loss,
        AVG(rtn.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT rtn.cr_refunded_customer_sk) AS distinct_customers,
        AVG(ccnt.web_page_cnt) AS avg_web_pages_per_customer
    FROM returns rtn
    JOIN call_center cc ON cc.cc_call_center_sk = rtn.cr_call_center_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = rtn.cr_ship_mode_sk
    JOIN reason r ON r.r_reason_sk = rtn.cr_reason_sk
    JOIN customer_counts ccnt ON ccnt.c_customer_sk = rtn.cr_refunded_customer_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc
    HAVING SUM(rtn.cr_return_amount) > 1000
)
SELECT
    call_center_name,
    shipping_type,
    return_reason,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    distinct_customers,
    avg_web_pages_per_customer,
    RANK() OVER (PARTITION BY call_center_name ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
