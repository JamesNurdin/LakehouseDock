WITH filtered AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_store_credit,
        cr.cr_return_quantity,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        c.c_customer_sk,
        c.c_last_name,
        c.c_salutation,
        r.r_reason_desc,
        t.t_hour,
        wp.wp_type
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE t.t_hour BETWEEN 9 AND 17                      -- business hours filter
      AND r.r_reason_desc LIKE '%color%'                -- reason contains the word "color"
      AND c.c_last_name = 'Moran'                       -- specific customer last name
      AND cr.cr_store_credit > 50.00                    -- store credit threshold
      AND EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_type = 'article'
        )                                                -- at least one article page for the customer
),
aggregated AS (
    SELECT
        r.r_reason_desc,
        c.c_last_name,
        t.t_hour,
        COUNT(*) AS returns_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_fee,
        MAX(cr.cr_store_credit) AS max_store_credit,
        CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'HighTotal' ELSE 'LowTotal' END AS total_category,
        (
            SELECT COUNT(*)
            FROM catalog_returns cr2
            WHERE cr2.cr_reason_sk = cr.cr_reason_sk
        ) AS total_returns_for_reason
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND r.r_reason_desc LIKE '%color%'
      AND c.c_last_name = 'Moran'
      AND cr.cr_store_credit > 50.00
      AND EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_type = 'article'
        )
    GROUP BY r.r_reason_desc, c.c_last_name, t.t_hour, cr.cr_reason_sk
)
SELECT
    a.r_reason_desc,
    a.c_last_name,
    a.t_hour,
    a.returns_cnt,
    a.total_return_amount,
    a.avg_fee,
    a.max_store_credit,
    a.total_category,
    a.total_returns_for_reason,
    ROW_NUMBER() OVER (PARTITION BY a.r_reason_desc ORDER BY a.total_return_amount DESC) AS rn_reason
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
