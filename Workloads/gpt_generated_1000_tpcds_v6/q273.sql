WITH catalog_customer_loss AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        REGEXP_EXTRACT(cp.cp_description, '(\\d{4})', 1) AS description_year
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE REGEXP_LIKE(c.c_first_name, '^A')
      AND cc.cc_city LIKE '%County%'
      AND cp.cp_type = 'monthly'
      AND REGEXP_EXTRACT(cp.cp_description, '(\\d{4})', 1) = '2022'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        REGEXP_EXTRACT(cp.cp_description, '(\\d{4})', 1)
)
SELECT
    ccl.c_customer_id,
    ccl.c_first_name,
    ccl.c_last_name,
    SUBSTRING(ccl.c_last_name, 1, 1) AS last_initial,
    ccl.catalog_net_loss,
    ccl.catalog_return_cnt,
    COALESCE(
        (
            SELECT SUM(wr.wr_net_loss)
            FROM web_returns wr
            JOIN web_sales ws
                ON wr.wr_order_number = ws.ws_order_number
            WHERE wr.wr_refunded_customer_sk = ccl.c_customer_sk
        ), 0
    ) AS web_net_loss,
    (ccl.catalog_net_loss + COALESCE(
        (
            SELECT SUM(wr.wr_net_loss)
            FROM web_returns wr
            JOIN web_sales ws
                ON wr.wr_order_number = ws.ws_order_number
            WHERE wr.wr_refunded_customer_sk = ccl.c_customer_sk
        ), 0
    )) AS total_net_loss
FROM catalog_customer_loss ccl
ORDER BY total_net_loss DESC
LIMIT 100
