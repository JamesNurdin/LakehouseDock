WITH sales AS (
    SELECT DISTINCT
        ss.ss_customer_sk AS customer_sk,
        CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END AS promo_channel,
        s.s_store_id AS store_id
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450915 AND 2450925
      AND p.p_channel_tv = 'N'
),
returns AS (
    SELECT DISTINCT
        sr.sr_customer_sk AS customer_sk,
        CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END AS promo_channel,
        s.s_store_id AS store_id
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450915 AND 2450925
)
SELECT
    customer_sk,
    promo_channel,
    store_id
FROM sales
EXCEPT
SELECT
    customer_sk,
    promo_channel,
    store_id
FROM returns
ORDER BY customer_sk
