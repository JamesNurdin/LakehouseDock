/* goal: Identify high‑value sales addresses and promotions that appear in store sales but not in catalog sales, then keep only those also exceeding a net‑paid threshold, and enrich with a count of all store sales for the address */
WITH store_data AS (
    SELECT ss.ss_addr_sk   AS address_sk,
           ss.ss_promo_sk  AS promo_sk,
           ss.ss_net_paid  AS net_paid
    FROM   store_sales ss
    JOIN   customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN   promotion p         ON ss.ss_promo_sk = p.p_promo_sk
    WHERE  ca.ca_state = 'CA'
       AND p.p_channel_event = 'N'
       AND EXISTS (
           SELECT 1
           FROM   promotion p2
           WHERE  p2.p_promo_sk = ss.ss_promo_sk
             AND  p2.p_discount_active = 'Y'
       )
),
catalog_data AS (
    SELECT cs.cs_bill_addr_sk AS address_sk,
           cs.cs_promo_sk    AS promo_sk,
           cs.cs_net_paid    AS net_paid
    FROM   catalog_sales cs
    JOIN   customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN   promotion p         ON cs.cs_promo_sk = p.p_promo_sk
    WHERE  ca.ca_state = 'CA'
       AND p.p_channel_event = 'N'
       AND EXISTS (
           SELECT 1
           FROM   promotion p3
           WHERE  p3.p_promo_sk = cs.cs_promo_sk
             AND  p3.p_discount_active = 'Y'
       )
)
SELECT final.address_sk,
       final.promo_sk,
       final.net_paid,
       lc.sales_cnt
FROM (
        (SELECT address_sk, promo_sk, net_paid
         FROM   store_data
         EXCEPT
         SELECT address_sk, promo_sk, net_paid
         FROM   catalog_data)
        INTERSECT
        SELECT address_sk, promo_sk, net_paid
        FROM   store_data
        WHERE  net_paid > 100
     ) AS final
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS sales_cnt
    FROM   store_sales ss3
    WHERE  ss3.ss_addr_sk = final.address_sk
) lc ON true
ORDER BY final.net_paid DESC
LIMIT 100
