WITH agg_returns AS (
    SELECT
        cr_order_number,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 100
    GROUP BY cr_order_number, cr_returned_date_sk
)
SELECT
    cs.cs_sold_date_sk,
    d.d_date,
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_net_paid_inc_ship_tax,
    ar.total_return_amount,
    ar.return_cnt,
    ca.ca_state,
    wp.wp_type,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY ar.total_return_amount DESC) AS state_return_rank,
    CASE WHEN cs.cs_coupon_amt > 500 THEN 'HighCoupon' ELSE 'LowCoupon' END AS coupon_category
FROM agg_returns ar
JOIN catalog_sales cs
    ON cs.cs_order_number = ar.cr_order_number
JOIN date_dim d
    ON d.d_date_sk = ar.cr_returned_date_sk
LEFT JOIN customer_address ca
    ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_weekend = 'N'
    AND cs.cs_net_paid_inc_ship_tax > 500
    AND ca.ca_state = 'CA'
    AND wp.wp_type = 'product'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 0
    )
ORDER BY ar.total_return_amount DESC
LIMIT 100
