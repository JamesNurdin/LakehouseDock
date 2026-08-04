/* Goal: Analyse net profit by promotion and item, illustrating string processing, sampling, lateral subqueries, and a full outer join between promotions and items. */
WITH sampled_cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
promo_item_full AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_item_sk,
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc
    FROM promotion p
    FULL OUTER JOIN item i
        ON p.p_item_sk = i.i_item_sk
),
cs_enriched AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS cs_promo_sk,
        cs.cs_item_sk AS cs_item_sk,
        w.w_warehouse_name,
        t.t_hour,
        i.i_product_name,
        i.i_item_desc,
        REGEXP_EXTRACT(i.i_item_desc, '(\\w+)$') AS last_word_desc,
        CASE
            WHEN REGEXP_LIKE(i.i_item_desc, '^.*[Ss]pecial.*$') THEN 'SPECIAL'
            ELSE 'REGULAR'
        END AS item_category_flag,
        CONCAT(i.i_brand, ' - ', COALESCE(p.p_promo_name, 'NoPromo')) AS brand_promo,
        lp.prod_name_prefix
    FROM sampled_cs cs
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
        SELECT SUBSTRING(i.i_product_name FROM 1 FOR 10) AS prod_name_prefix
    ) lp ON TRUE
)
SELECT
    COALESCE(pi.p_promo_name, 'NoPromo') AS promo_name,
    COALESCE(pi.i_product_name, 'NoItem') AS product_name,
    SUM(cs.net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.order_number) AS orders_cnt,
    AVG(cs.quantity) AS avg_quantity
FROM cs_enriched cs
FULL OUTER JOIN promo_item_full pi
    ON cs.cs_promo_sk = pi.p_promo_sk
    AND cs.cs_item_sk = pi.i_item_sk
GROUP BY
    COALESCE(pi.p_promo_name, 'NoPromo'),
    COALESCE(pi.i_product_name, 'NoItem')
ORDER BY total_net_profit DESC
LIMIT 100
