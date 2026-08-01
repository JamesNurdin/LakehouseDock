WITH
/* Customers who have catalog returns */
return_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS customer_sk
    FROM catalog_returns cr
),
/* Customers who bought a promotion containing the word 'Summer' on both web and store channels */
promo_customers_web AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%Summer%'
),
promo_customers_store AS (
    SELECT ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%Summer%'
),
common_promo_customers AS (
    SELECT customer_sk FROM promo_customers_web
    INTERSECT
    SELECT customer_sk FROM promo_customers_store
),
/* Web‑sales rows that satisfy string‑based filters */
ws_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_web_page_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_net_paid DESC) AS rn_customer
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*electronics.*')                 -- URL contains “electronics”
      AND wp.wp_type LIKE '%detail%'                                        -- page type contains “detail”
      AND (CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) = 1         -- promotion sent by e‑mail
),
/* Store‑sales rows that match the same promotion */
ss_filtered AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_net_paid AS net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_net_paid DESC) AS rn_customer
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%Summer%'
      AND ss.ss_quantity > 10
)
/* Union of web and store sales after applying anti‑join and intersection criteria */
SELECT DISTINCT
    c.c_customer_id,
    w.w_warehouse_name,
    p.p_promo_name,
    src.net_paid,
    src.domain,
    src.rn_customer
FROM (
    /* Web‑sales branch */
    SELECT
        wf.ws_bill_customer_sk   AS cust_sk,
        wf.ws_warehouse_sk       AS warehouse_sk,
        wf.ws_promo_sk           AS promo_sk,
        wf.ws_net_paid           AS net_paid,
        l.domain,
        wf.rn_customer
    FROM ws_filtered wf
    JOIN warehouse w ON wf.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON wf.ws_promo_sk = p.p_promo_sk
    /* LATERAL to pull domain from the URL */
    LEFT JOIN LATERAL (
        SELECT regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wf.ws_web_page_sk
    ) l ON TRUE
    WHERE NOT EXISTS (
        SELECT 1 FROM return_customers rc WHERE rc.customer_sk = wf.ws_bill_customer_sk
    )
      AND wf.ws_bill_customer_sk IN (SELECT customer_sk FROM common_promo_customers)

    UNION

    /* Store‑sales branch (warehouse name not available – set to NULL) */
    SELECT
        sf.cust_sk               AS cust_sk,
        NULL                     AS warehouse_sk,
        sf.promo_sk              AS promo_sk,
        sf.net_paid              AS net_paid,
        NULL                     AS domain,
        sf.rn_customer
    FROM ss_filtered sf
    WHERE NOT EXISTS (
        SELECT 1 FROM return_customers rc WHERE rc.customer_sk = sf.cust_sk
    )
      AND sf.cust_sk IN (SELECT customer_sk FROM common_promo_customers)
) src
JOIN customer c ON src.cust_sk = c.c_customer_sk
LEFT JOIN warehouse w ON src.warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p ON src.promo_sk = p.p_promo_sk
ORDER BY src.net_paid DESC
LIMIT 100
