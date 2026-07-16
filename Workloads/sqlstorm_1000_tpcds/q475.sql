WITH all_sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit,
           ss_sales_price AS sales_price,
           ss_ticket_number AS order_number,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_net_profit,
           cs_sales_price,
           cs_order_number,
           'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_profit,
           ws_sales_price,
           ws_order_number,
           'web'
    FROM web_sales
),
sales_with_promo AS (
    SELECT s.*,
           p.p_promo_name
    FROM all_sales s
    LEFT JOIN promotion p
      ON p.p_item_sk = s.item_sk
      AND s.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
),
sales_by_month_item AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        SUM(CASE WHEN s.channel = 'store' THEN s.net_profit END) AS store_net_profit,
        SUM(CASE WHEN s.channel = 'catalog' THEN s.net_profit END) AS catalog_net_profit,
        SUM(CASE WHEN s.channel = 'web' THEN s.net_profit END) AS web_net_profit,
        SUM(CASE WHEN s.channel = 'store' THEN s.sales_price END) AS store_sales_price,
        SUM(CASE WHEN s.channel = 'catalog' THEN s.sales_price END) AS catalog_sales_price,
        SUM(CASE WHEN s.channel = 'web' THEN s.sales_price END) AS web_sales_price,
        COUNT(DISTINCT CASE WHEN s.channel = 'store' THEN s.order_number END) AS store_order_cnt,
        COUNT(DISTINCT CASE WHEN s.channel = 'catalog' THEN s.order_number END) AS catalog_order_cnt,
        COUNT(DISTINCT CASE WHEN s.channel = 'web' THEN s.order_number END) AS web_order_cnt,
        MAX(s.p_promo_name) AS promo_name
    FROM sales_with_promo s
    JOIN date_dim d ON d.d_date_sk = s.date_sk
    JOIN item i ON i.i_item_sk = s.item_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name, i.i_category, i.i_brand
),
ranked_products AS (
    SELECT
        s.*,
        COALESCE(s.store_net_profit,0) + COALESCE(s.catalog_net_profit,0) + COALESCE(s.web_net_profit,0) AS total_net_profit,
        COALESCE(s.store_sales_price,0) + COALESCE(s.catalog_sales_price,0) + COALESCE(s.web_sales_price,0) AS total_sales_price,
        CASE 
            WHEN COALESCE(s.store_sales_price,0) + COALESCE(s.catalog_sales_price,0) + COALESCE(s.web_sales_price,0) = 0 
                THEN NULL
                ELSE ROUND(
                    (COALESCE(s.store_net_profit,0) + COALESCE(s.catalog_net_profit,0) + COALESCE(s.web_net_profit,0))
                    / NULLIF(COALESCE(s.store_sales_price,0) + COALESCE(s.catalog_sales_price,0) + COALESCE(s.web_sales_price,0), 0)
                , 4)
        END AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY COALESCE(s.store_net_profit,0) + COALESCE(s.catalog_net_profit,0) + COALESCE(s.web_net_profit,0) DESC) AS rn,
        CONCAT(s.i_product_name, ' (', s.i_category, ')') AS product_desc,
        CASE 
            WHEN COALESCE(s.store_net_profit,0) + COALESCE(s.catalog_net_profit,0) + COALESCE(s.web_net_profit,0) IS NULL THEN 'No Sales'
            ELSE 'Has Sales'
        END AS sales_flag,
        LOWER(REGEXP_REPLACE(CONCAT(s.i_product_name, '-', s.i_brand), '[^a-z0-9]+', '-')) AS product_slug,
        (SELECT SUM(COALESCE(x.store_net_profit,0) + COALESCE(x.catalog_net_profit,0) + COALESCE(x.web_net_profit,0))
         FROM sales_by_month_item x
         WHERE x.i_brand = s.i_brand
           AND x.d_year = s.d_year
           AND x.d_month_seq = s.d_month_seq) AS brand_month_total_profit,
        (SELECT SUM(COALESCE(x.store_sales_price,0) + COALESCE(x.catalog_sales_price,0) + COALESCE(x.web_sales_price,0))
         FROM sales_by_month_item x
         WHERE x.i_brand = s.i_brand
           AND x.d_year = s.d_year
           AND x.d_month_seq = s.d_month_seq) AS brand_month_total_sales
    FROM sales_by_month_item s
),
brand_avg AS (
    SELECT
        i_brand,
        AVG(total_net_profit) AS avg_brand_profit
    FROM ranked_products
    GROUP BY i_brand
),
brand_promo_counts AS (
    SELECT
        i.i_brand,
        COUNT(DISTINCT p.p_promo_name) AS promo_count
    FROM promotion p
    JOIN item i ON i.i_item_sk = p.p_item_sk
    GROUP BY i.i_brand
),
brand_stats AS (
    SELECT
        COALESCE(a.i_brand, b.i_brand) AS i_brand,
        a.avg_brand_profit,
        b.promo_count
    FROM brand_avg a
    FULL OUTER JOIN brand_promo_counts b
      ON a.i_brand = b.i_brand
),
final AS (
    SELECT
        rp.d_year,
        rp.d_month_seq,
        rp.product_desc,
        rp.i_category,
        rp.i_brand,
        rp.total_net_profit,
        rp.total_sales_price,
        rp.profit_margin,
        rp.rn,
        bs.avg_brand_profit,
        bs.promo_count,
        CASE WHEN rp.total_net_profit > bs.avg_brand_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_brand,
        rp.sales_flag,
        rp.promo_name,
        rp.product_slug,
        CASE WHEN rp.brand_month_total_profit > 0 THEN ROUND(rp.total_net_profit / rp.brand_month_total_profit * 100, 2) ELSE NULL END AS pct_of_brand_month_profit,
        CASE WHEN rp.brand_month_total_sales > 0 THEN ROUND(rp.total_sales_price / rp.brand_month_total_sales * 100, 2) ELSE NULL END AS pct_of_brand_month_sales
    FROM ranked_products rp
    JOIN brand_stats bs ON bs.i_brand = rp.i_brand
    WHERE rp.rn <= 10
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        CONCAT('TOTAL ', CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_month_seq AS VARCHAR),2,'0')),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS VARCHAR),
        SUM(COALESCE(s.store_net_profit,0) + COALESCE(s.catalog_net_profit,0) + COALESCE(s.web_net_profit,0)),
        SUM(COALESCE(s.store_sales_price,0) + COALESCE(s.catalog_sales_price,0) + COALESCE(s.web_sales_price,0)),
        CAST(NULL AS DOUBLE),
        CAST(NULL AS BIGINT),
        CAST(NULL AS DOUBLE),
        CAST(NULL AS BIGINT),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS VARCHAR),
        CAST(NULL AS DOUBLE),
        CAST(NULL AS DOUBLE)
    FROM sales_by_month_item s
    JOIN date_dim d ON d.d_year = s.d_year AND d.d_month_seq = s.d_month_seq
    GROUP BY d.d_year, d.d_month_seq
)
SELECT *
FROM final
ORDER BY d_year, d_month_seq, total_net_profit DESC NULLS LAST
