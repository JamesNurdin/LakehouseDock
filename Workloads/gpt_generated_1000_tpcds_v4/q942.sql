WITH combined AS (
    -- Sales side with promotion information
    SELECT
        p.p_promo_name AS promo_name,
        ca.ca_state AS state,
        ss.ss_net_profit AS amount,
        'sale' AS src
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_radio = 'N'
      AND p.p_purpose = 'Unknown'
      AND ca.ca_state = 'CA'
      AND ss.ss_coupon_amt > 0
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100

    UNION ALL

    -- Returns side (no promotion join, use NULL for promo_name)
    SELECT
        CAST(NULL AS varchar) AS promo_name,
        ca.ca_state AS state,
        -cr.cr_fee AS amount,
        'return' AS src
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_fee > 20
      AND ca.ca_state = 'CA'
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr.cr_return_quantity > 1
)
SELECT
    promo_name,
    state,
    SUM(CASE WHEN src = 'sale' THEN amount ELSE 0 END) AS total_sales_profit,
    SUM(CASE WHEN src = 'return' THEN amount ELSE 0 END) AS total_return_fee,
    COUNT(CASE WHEN src = 'sale' THEN 1 END) AS sales_count,
    COUNT(CASE WHEN src = 'return' THEN 1 END) AS return_count,
    (
        SELECT AVG(cr2.cr_fee)
        FROM catalog_returns cr2
        JOIN customer_address ca2 ON cr2.cr_refunded_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_state = combined.state
    ) AS avg_return_fee_state
FROM combined
WHERE amount IS NOT NULL
GROUP BY promo_name, state
HAVING SUM(CASE WHEN src = 'sale' THEN amount ELSE 0 END) > 500
ORDER BY total_sales_profit DESC
LIMIT 100
