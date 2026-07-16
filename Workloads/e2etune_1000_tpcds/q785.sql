WITH returns_by_cc_month AS (
    SELECT
        cc.cc_call_center_id AS cc_id,
        date_trunc('month', date_parse(cast(cr.cr_returned_date_sk AS varchar), '%Y%m%d')) AS return_month,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
        COUNT(DISTINCT CASE WHEN wp.wp_web_page_sk IS NOT NULL THEN cr.cr_returning_customer_sk END) AS distinct_customers_with_web_page
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_division IN (1, 2, 3)
      AND cr.cr_return_amount > 0
      AND cr.cr_returned_date_sk BETWEEN 19970101 AND 19971231
    GROUP BY cc.cc_call_center_id,
        date_trunc('month', date_parse(cast(cr.cr_returned_date_sk AS varchar), '%Y%m%d'))
)
SELECT
    cc_id,
    return_month,
    total_return_amount,
    total_return_amount_inc_tax,
    avg_return_tax,
    total_net_loss,
    distinct_returning_customers,
    distinct_customers_with_web_page,
    (distinct_customers_with_web_page * 100.0 / NULLIF(distinct_returning_customers, 0)) AS pct_customers_with_web_page,
    RANK() OVER (PARTITION BY cc_id ORDER BY total_return_amount DESC) AS return_amount_rank
FROM returns_by_cc_month
WHERE distinct_returning_customers >= 5
ORDER BY cc_id, return_month
