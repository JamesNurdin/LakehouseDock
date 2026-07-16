WITH
date_year AS (
    SELECT d_date_sk, d_year, d_month_seq, d_week_seq
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
),
catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        d.d_year,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_year d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, d.d_year
),
store_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        d.d_year,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_year d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, d.d_year
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_year d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, d.d_year
),
combined AS (
    SELECT
        COALESCE(ca.i_item_id, sa.i_item_id, wa.i_item_id) AS i_item_id,
        COALESCE(ca.i_item_desc, sa.i_item_desc, wa.i_item_desc) AS i_item_desc,
        COALESCE(ca.i_category, sa.i_category, wa.i_category) AS i_category,
        COALESCE(ca.d_year, sa.d_year, wa.d_year) AS d_year,
        ca.catalog_orders,
        ca.catalog_quantity,
        ca.catalog_sales,
        ca.catalog_discount,
        ca.catalog_profit,
        sa.store_orders,
        sa.store_quantity,
        sa.store_sales,
        sa.store_discount,
        sa.store_profit,
        wa.web_orders,
        wa.web_quantity,
        wa.web_sales,
        wa.web_discount,
        wa.web_profit
    FROM catalog_agg ca
    FULL OUTER JOIN store_agg sa ON ca.i_item_id = sa.i_item_id AND ca.d_year = sa.d_year
    FULL OUTER JOIN web_agg wa ON COALESCE(ca.i_item_id, sa.i_item_id) = wa.i_item_id AND COALESCE(ca.d_year, sa.d_year) = wa.d_year
),
final AS (
    SELECT
        i_item_id,
        i_item_desc,
        i_category,
        d_year,
        COALESCE(catalog_orders,0) + COALESCE(store_orders,0) + COALESCE(web_orders,0) AS total_orders,
        COALESCE(catalog_quantity,0) + COALESCE(store_quantity,0) + COALESCE(web_quantity,0) AS total_quantity,
        COALESCE(catalog_sales,0) + COALESCE(store_sales,0) + COALESCE(web_sales,0) AS total_sales,
        COALESCE(catalog_discount,0) + COALESCE(store_discount,0) + COALESCE(web_discount,0) AS total_discount,
        COALESCE(catalog_profit,0) + COALESCE(store_profit,0) + COALESCE(web_profit,0) AS total_profit,
        ROW_NUMBER() OVER (
            PARTITION BY i_category
            ORDER BY (COALESCE(catalog_sales,0) + COALESCE(store_sales,0) + COALESCE(web_sales,0)) DESC
        ) AS sales_rank_in_category,
        CASE
            WHEN (COALESCE(catalog_sales,0) + COALESCE(store_sales,0) + COALESCE(web_sales,0)) > 1000000 THEN 'High'
            WHEN (COALESCE(catalog_sales,0) + COALESCE(store_sales,0) + COALESCE(web_sales,0)) > 500000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_tier
    FROM combined
)
SELECT
    i_item_id,
    i_item_desc,
    i_category,
    d_year,
    total_orders,
    total_quantity,
    total_sales,
    total_discount,
    total_profit,
    sales_rank_in_category,
    sales_tier
FROM final
WHERE d_year = 2000
ORDER BY i_category, sales_rank_in_category
LIMIT 100
