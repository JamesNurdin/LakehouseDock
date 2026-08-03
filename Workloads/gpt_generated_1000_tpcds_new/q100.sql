WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        i.i_category,
        p.p_promo_name,
        w.w_city,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit AS web_net_profit,
        ss.ss_ext_discount_amt,
        ws.ws_ext_discount_amt,
        lt.store_line_total
    FROM sampled_store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT ss.ss_quantity * ss.ss_sales_price AS store_line_total
    ) lt
    WHERE
        w.w_country = 'United States'
        AND w.w_suite_number = 'Suite 80'
        AND p.p_channel_catalog = 'N'
        AND p.p_response_target = 1
        AND i.i_class = 'sports-apparel'
        AND i.i_manufact_id = 260
        AND p.p_end_date_sk = 2450646
),
aggregated AS (
    SELECT
        i_category,
        p_promo_name,
        w_city,
        SUM(store_net_profit) AS total_store_profit,
        SUM(web_net_profit) AS total_web_profit,
        COUNT(*) AS transaction_count,
        AVG(ss_ext_discount_amt) AS avg_store_discount,
        AVG(ws_ext_discount_amt) AS avg_web_discount,
        SUM(store_line_total) AS total_store_line
    FROM joined
    GROUP BY
        i_category,
        p_promo_name,
        w_city
)
SELECT
    i_category,
    p_promo_name,
    w_city,
    total_store_profit,
    total_web_profit,
    transaction_count,
    avg_store_discount,
    avg_web_discount,
    total_store_line,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_store_profit DESC) AS category_rank
FROM aggregated
ORDER BY total_store_profit DESC
LIMIT 100
