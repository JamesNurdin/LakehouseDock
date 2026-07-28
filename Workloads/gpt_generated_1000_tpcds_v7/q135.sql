WITH base AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        d.d_date,
        c.c_birth_day,
        cd.cd_gender,
        r.r_reason_desc,
        cr.cr_return_tax,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cc.cc_employees,
        p.p_discount_active,
        p.p_promo_sk,
        wp.wp_char_count
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND c.c_birth_day BETWEEN 1 AND 15
      AND cr.cr_return_tax > 5.0
      AND cs.cs_net_profit > 0
      AND cc.cc_employees > 50
      AND p.p_discount_active = 'Y'
)
SELECT
    p2.p_promo_id,
    COUNT(DISTINCT b.sr_customer_sk) AS distinct_customers,
    SUM(b.cs_ext_sales_price) AS total_sales,
    AVG(b.cs_net_profit) AS avg_profit,
    SUM(b.cr_return_tax) AS total_return_tax,
    (
        SELECT MAX(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_promo_sk = p2.p_promo_sk
    ) AS max_net_paid
FROM base b
JOIN promotion p2
    ON b.p_promo_sk = p2.p_promo_sk
GROUP BY p2.p_promo_id, p2.p_promo_sk
HAVING AVG(b.cs_net_profit) > 10
ORDER BY total_sales DESC
LIMIT 100
