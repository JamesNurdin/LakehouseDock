WITH catalog_part AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.cs_net_paid_inc_tax,
        p.p_promo_name,
        (
            SELECT SUM(cs2.cs_net_paid_inc_tax)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
        ) AS total_customer_net_paid
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_item_sk IN (
        SELECT p2.p_item_sk
        FROM promotion p2
        WHERE p2.p_discount_active = 'Y'
    )
    AND cs.cs_net_paid_inc_tax > 1000
),
store_part AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.ss_net_paid_inc_tax,
        p.p_promo_name,
        (
            SELECT SUM(ss2.ss_net_paid_inc_tax)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c.c_customer_sk
        ) AS total_customer_net_paid
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_item_sk IN (
        SELECT p2.p_item_sk
        FROM promotion p2
        WHERE p2.p_discount_active = 'Y'
    )
    AND ss.ss_net_paid_inc_tax > 1000
)
SELECT combined.c_customer_id,
       combined.c_first_name,
       combined.c_last_name,
       combined.net_paid,
       combined.p_promo_name,
       combined.total_customer_net_paid
FROM (
    SELECT c_customer_id,
           c_first_name,
           c_last_name,
           cs_net_paid_inc_tax AS net_paid,
           p_promo_name,
           total_customer_net_paid
    FROM catalog_part
    UNION
    SELECT c_customer_id,
           c_first_name,
           c_last_name,
           ss_net_paid_inc_tax AS net_paid,
           p_promo_name,
           total_customer_net_paid
    FROM store_part
) AS combined
ORDER BY combined.net_paid DESC
LIMIT 100
