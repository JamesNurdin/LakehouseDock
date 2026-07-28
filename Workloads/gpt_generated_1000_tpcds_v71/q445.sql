WITH catalog_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_brand = 'Brand#45'
      AND ca.ca_state = 'CA'
    GROUP BY r.r_reason_desc
),
web_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_brand = 'Brand#45'
      AND ca.ca_state = 'CA'
    GROUP BY r.r_reason_desc
)
SELECT
    reason_desc,
    total_return_amount,
    cnt_returns,
    source
FROM (
    SELECT reason_desc, total_return_amount, cnt_returns, 'catalog' AS source FROM catalog_ret
    UNION ALL
    SELECT reason_desc, total_return_amount, cnt_returns, 'web' AS source FROM web_ret
) combined
ORDER BY total_return_amount DESC
LIMIT 100
