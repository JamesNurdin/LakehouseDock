WITH aggregated_returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        i.i_product_name AS product_name,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt,
        CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_group,
        'store' AS return_source
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2001-12-31'
    GROUP BY sr.sr_customer_sk, c.c_first_name, c.c_last_name, i.i_product_name, cd.cd_marital_status
    UNION ALL
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        i.i_product_name AS product_name,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt,
        CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_group,
        'catalog' AS return_source
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2001-12-31'
    GROUP BY cr.cr_refunded_customer_sk, c.c_first_name, c.c_last_name, i.i_product_name, cd.cd_marital_status
)
SELECT
    customer_sk,
    first_name,
    last_name,
    product_name,
    total_return_inc_tax,
    return_cnt,
    marital_group,
    return_source,
    ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_return_inc_tax DESC) AS rn_per_customer,
    SUM(total_return_inc_tax) OVER (
        PARTITION BY marital_group
        ORDER BY total_return_inc_tax DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_marital
FROM aggregated_returns
WHERE total_return_inc_tax > 0
ORDER BY total_return_inc_tax DESC
LIMIT 100
