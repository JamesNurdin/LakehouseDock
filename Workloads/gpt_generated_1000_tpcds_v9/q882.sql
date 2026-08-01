WITH
sales_detail AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '([0-9]+)', 1) AS promo_number,
        CASE
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail'
            ELSE 'Other'
        END AS primary_channel,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS discount_status,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_promo_name, 'Discount')
      AND p.p_promo_name LIKE '%2023%'
),
catalog_detail AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '([0-9]+)', 1) AS promo_number,
        CASE
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_dmail = 'Y' THEN 'DirectMail'
            ELSE 'Other'
        END AS primary_channel,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS discount_status,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_promo_name, 'Discount')
      AND p.p_promo_name LIKE '%2023%'
),
store_agg AS (
    SELECT
        p_promo_id,
        primary_channel,
        discount_status,
        promo_number,
        city_state,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_net_paid) AS total_net_paid
    FROM sales_detail
    GROUP BY ROLLUP(p_promo_id, primary_channel, discount_status, promo_number, city_state)
    HAVING SUM(ss_net_profit) > 1000
),
catalog_agg AS (
    SELECT
        p_promo_id,
        primary_channel,
        discount_status,
        promo_number,
        city_state,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_net_paid) AS total_net_paid
    FROM catalog_detail
    GROUP BY ROLLUP(p_promo_id, primary_channel, discount_status, promo_number, city_state)
    HAVING SUM(cs_net_profit) > 1000
)
SELECT
    p_promo_id,
    primary_channel,
    discount_status,
    promo_number,
    city_state,
    total_net_profit,
    total_net_paid
FROM store_agg
EXCEPT
SELECT
    p_promo_id,
    primary_channel,
    discount_status,
    promo_number,
    city_state,
    total_net_profit,
    total_net_paid
FROM catalog_agg
ORDER BY total_net_profit DESC
LIMIT 100
