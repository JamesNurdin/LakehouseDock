WITH refunded_demo AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        i.i_brand,
        i.i_category,
        i.i_color,
        cd_ref.cd_gender,
        c.c_preferred_cust_flag
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE cr.cr_return_amount > 500
      AND i.i_current_price BETWEEN 50 AND 500
      AND cd_ref.cd_purchase_estimate >= 4000
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd_ret
          WHERE cd_ret.cd_demo_sk = cr.cr_returning_cdemo_sk
            AND cd_ret.cd_purchase_estimate > 5000
            AND cd_ret.cd_dep_college_count >= 1
      )
)
SELECT
    i_brand,
    i_category,
    i_color,
    cd_gender,
    c_preferred_cust_flag,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount
FROM refunded_demo
GROUP BY
    i_brand,
    i_category,
    i_color,
    cd_gender,
    c_preferred_cust_flag
ORDER BY total_return_amount DESC
LIMIT 100
