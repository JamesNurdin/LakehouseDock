WITH
    recent_sales AS (
        SELECT
            ss.ss_customer_sk,
            ss.ss_item_sk,
            i.i_item_id,
            i.i_product_name,
            CONCAT(i.i_item_id, '_', i.i_brand) AS item_key,
            CASE WHEN regexp_like(i.i_product_name, '[A-Z]{3}') THEN 'HAS3CAP' ELSE 'NO_CAP' END AS caps_flag,
            ss.ss_net_paid AS net_paid,
            d.d_year
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d.d_year = 2002
          AND i.i_item_id LIKE '00%'
    ),
    promo_items AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_name,
            i.i_item_id,
            i.i_product_name
        FROM promotion p
        JOIN item i ON p.p_item_sk = i.i_item_sk
        WHERE regexp_like(p.p_promo_name, 'discount')
    ),
    max_profit_cte AS (
        SELECT max(cs.cs_net_profit) AS max_profit
        FROM catalog_sales cs
    )
SELECT *
FROM (
    SELECT
        item_key,
        caps_flag,
        SUM(net_paid) AS total_paid,
        COUNT(*) AS cnt
    FROM (
        SELECT item_key, caps_flag, net_paid FROM recent_sales
        UNION
        SELECT
            CONCAT(p.p_promo_name, '_', i.i_item_id) AS item_key,
            'PROMO' AS caps_flag,
            cs.cs_net_paid AS net_paid
        FROM catalog_sales cs
        JOIN promo_items p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_net_paid > (SELECT max_profit FROM max_profit_cte)
    ) u
    GROUP BY item_key, caps_flag
    HAVING SUM(net_paid) > 500
) a
INTERSECT
SELECT *
FROM (
    SELECT
        item_key,
        caps_flag,
        SUM(net_paid) AS total_paid,
        COUNT(*) AS cnt
    FROM (
        SELECT item_key, caps_flag, net_paid FROM recent_sales
        UNION
        SELECT
            CONCAT(p.p_promo_name, '_', i.i_item_id) AS item_key,
            'PROMO' AS caps_flag,
            cs.cs_net_paid AS net_paid
        FROM catalog_sales cs
        JOIN promo_items p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
    ) v
    GROUP BY item_key, caps_flag
    HAVING SUM(net_paid) > 500
) b
ORDER BY total_paid DESC
LIMIT 100
