WITH return_agg AS (
    SELECT
        r.r_reason_desc AS category_desc,
        c.c_customer_id,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_reversed_charge > 20
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY r.r_reason_desc, c.c_customer_id
    HAVING SUM(cr.cr_return_amount) > 100
),
web_sales_agg AS (
    SELECT
        p.p_promo_name AS category_desc,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_amount,
        COUNT(*) AS cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_coupon_amt > 1000
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ws.ws_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY p.p_promo_name, c.c_customer_id
    HAVING SUM(ws.ws_net_paid) > 5000
)
SELECT category_desc,
       c_customer_id,
       total_amount,
       cnt
FROM return_agg
UNION ALL
SELECT category_desc,
       c_customer_id,
       total_amount,
       cnt
FROM web_sales_agg
ORDER BY total_amount DESC
LIMIT 100
