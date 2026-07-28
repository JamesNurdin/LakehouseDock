/*
Goal: Identify the most profitable product brands for sales that were driven by promotions containing the word "discount" and whose product names follow a specific alphanumeric pattern (e.g., three capital letters followed by digits). The query extracts the three‑letter prefix from the product name, filters on the pattern, aggregates profit metrics per brand, and returns the top 10 brands by total profit.
*/
WITH filtered_sales AS (
    SELECT
        i.i_brand,
        i.i_brand_id,
        p.p_promo_name,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        regexp_extract(i.i_product_name, '^([A-Z]{3})[0-9]+', 1) AS prod_prefix
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')               -- promotion name contains "discount" (case‑insensitive)
      AND i.i_product_name LIKE '%-%'                               -- product name contains a hyphen somewhere
      AND regexp_extract(i.i_product_name, '^([A-Z]{3})[0-9]+', 1) IS NOT NULL  -- matches three letters + digits at start
)
SELECT
    i_brand,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_net_profit) AS avg_profit,
    MAX(ss_net_profit) AS max_profit,
    MIN(ss_net_profit) AS min_profit,
    SUM(CASE WHEN prod_prefix = 'ABC' THEN ss_net_profit ELSE 0 END) AS abc_profit
FROM filtered_sales
GROUP BY i_brand
ORDER BY total_profit DESC
LIMIT 10
