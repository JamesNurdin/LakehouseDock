WITH store_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        ss.ss_net_paid AS net_paid,
        'store' AS sales_channel,
        t.t_hour AS sale_hour
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND p.p_channel_email = 'Y'
),
catalog_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        cs.cs_net_paid AS net_paid,
        'catalog' AS sales_channel,
        t.t_hour AS sale_hour
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE t.t_hour BETWEEN 18 AND 23
      AND p.p_channel_tv = 'Y'
)
SELECT *
FROM (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM catalog_part
) combined
ORDER BY net_paid DESC
LIMIT 100
