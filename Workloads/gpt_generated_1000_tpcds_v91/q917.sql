WITH promo_sales_1 AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        uv.channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        (
            SELECT SUM(ss2.ss_quantity)
            FROM store_sales ss2
            WHERE ss2.ss_promo_sk = p.p_promo_sk
        ) AS total_quantity_for_promo
    FROM promotion p
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS uv(channel)
    WHERE p.p_discount_active = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY p.p_promo_id, p.p_promo_name, uv.channel, p.p_promo_sk
),
promo_sales_2 AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        uv.channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        (
            SELECT SUM(ss2.ss_quantity)
            FROM store_sales ss2
            WHERE ss2.ss_promo_sk = p.p_promo_sk
        ) AS total_quantity_for_promo
    FROM promotion p
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS uv(channel)
    WHERE p.p_channel_tv = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2452000 AND 2453000
    GROUP BY p.p_promo_id, p.p_promo_name, uv.channel, p.p_promo_sk
)
SELECT
    p1.p_promo_id,
    p1.p_promo_name,
    p1.channel,
    p1.total_sales,
    p1.num_tickets,
    p1.total_quantity_for_promo
FROM promo_sales_1 p1
UNION ALL
SELECT
    p2.p_promo_id,
    p2.p_promo_name,
    p2.channel,
    p2.total_sales,
    p2.num_tickets,
    p2.total_quantity_for_promo
FROM promo_sales_2 p2
ORDER BY total_sales DESC
LIMIT 100
