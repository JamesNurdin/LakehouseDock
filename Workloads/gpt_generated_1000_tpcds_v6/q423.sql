WITH high_spenders AS (
    SELECT c.c_customer_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid_inc_ship > 3000
    GROUP BY c.c_customer_sk
    HAVING COUNT(*) >= 2
)
SELECT
    r.customer_id,
    r.activity_type,
    SUM(r.amount) AS total_amount,
    CASE WHEN SUM(r.amount) > 5000 THEN 'High' ELSE 'Low' END AS amount_category,
    COUNT(DISTINCT r.activity_date) AS distinct_days
FROM (
    -- Catalog sales side
    SELECT
        c.c_customer_id AS customer_id,
        'sale' AS activity_type,
        cs.cs_net_paid_inc_ship AS amount,
        DATE '2022-01-01' + INTERVAL '1' DAY * cs.cs_sold_date_sk AS activity_date
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number IN (10, 11, 16)
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_discount_active = 'Y'
      )
      AND c.c_customer_sk IN (SELECT c_customer_sk FROM high_spenders)

    UNION ALL

    -- Web returns side
    SELECT
        c.c_customer_id AS customer_id,
        'return' AS activity_type,
        -wr.wr_return_amt AS amount,
        DATE '2022-01-01' + INTERVAL '1' DAY * wr.wr_returned_date_sk AS activity_date
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND c.c_customer_sk IN (SELECT c_customer_sk FROM high_spenders)
) AS r
GROUP BY r.customer_id, r.activity_type
ORDER BY total_amount DESC
LIMIT 100
