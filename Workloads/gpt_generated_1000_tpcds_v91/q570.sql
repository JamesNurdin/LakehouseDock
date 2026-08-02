WITH store_ret AS (
    SELECT
        d.d_date AS return_date,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amount,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        'store' AS channel,
        CASE WHEN s.s_tax_percentage > 5 THEN 'high_tax' ELSE 'low_tax' END AS category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_store_sk IN (
        SELECT s2.s_store_sk
        FROM store s2
        WHERE s2.s_state = 'CA'
    )
      AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-01-31'
),
web_ret AS (
    SELECT
        d.d_date AS return_date,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amount,
        wr.wr_returning_customer_sk AS customer_sk,
        wr.wr_item_sk AS item_sk,
        'web' AS channel,
        CASE WHEN wp.wp_type = 'C' THEN 'type_c' ELSE 'other_type' END AS category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'C'
      AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-01-31'
)
SELECT
    ROW_NUMBER() OVER (ORDER BY combined.return_date DESC) AS row_num,
    combined.channel,
    combined.return_date,
    SUM(combined.return_amount) AS total_return_amount,
    SUM(combined.return_quantity) AS total_return_quantity,
    COUNT(DISTINCT combined.customer_sk) AS distinct_customers,
    COUNT(DISTINCT combined.item_sk) AS distinct_items,
    COUNT(DISTINCT combined.category) AS distinct_categories
FROM (
    SELECT
        return_date,
        return_quantity,
        return_amount,
        customer_sk,
        item_sk,
        channel,
        category
    FROM store_ret
    UNION ALL
    SELECT
        return_date,
        return_quantity,
        return_amount,
        customer_sk,
        item_sk,
        channel,
        category
    FROM web_ret
) AS combined
GROUP BY
    combined.channel,
    combined.return_date
ORDER BY
    combined.return_date DESC
LIMIT 100
