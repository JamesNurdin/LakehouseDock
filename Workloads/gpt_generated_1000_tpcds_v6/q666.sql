WITH high_value_customers AS (
    SELECT c_customer_id
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
)
SELECT *
FROM (
    SELECT
        c.c_customer_id AS customer_id,
        cc.cc_name AS channel_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'Catalog' AS source
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_amount > 50
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY c.c_customer_id, cc.cc_name

    UNION ALL

    SELECT
        c.c_customer_id AS customer_id,
        wp.wp_url AS channel_name,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'Web' AS source
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt_inc_tax > 50
      AND wp.wp_link_count > 10
    GROUP BY c.c_customer_id, wp.wp_url
) combined
WHERE combined.customer_id IN (SELECT c_customer_id FROM high_value_customers)
ORDER BY combined.total_return_amount DESC
LIMIT 100
