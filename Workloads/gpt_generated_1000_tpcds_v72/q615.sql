/* goal: Identify the top product categories and brands in 2001 web sales where the product name starts with an 'A' followed by a digit and contains the word 'Widget'. The query uses active promotions, applies regular‑expression filters, a scalar sub‑query for overall average profit, and a window function to rank results. */
WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_net_profit,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        p.p_discount_active
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_product_name, '^A.*[0-9]')
      AND i.i_product_name LIKE '%Widget%'
      AND p.p_discount_active = 'Y'
),
aggregated AS (
    SELECT
        i_category,
        i_brand,
        i_product_name,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM filtered_sales
    GROUP BY i_category, i_brand, i_product_name
    HAVING SUM(ws_net_profit) > (
        SELECT AVG(ws3.ws_net_profit) * 1.5
        FROM web_sales ws3
        JOIN date_dim d3 ON ws3.ws_sold_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
    )
),
final AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (ORDER BY a.total_net_profit DESC) AS rank,
        concat(a.i_brand, ' - ', a.i_product_name) AS brand_product,
        regexp_extract(a.i_product_name, '^([A-Za-z]+)', 1) AS first_word,
        (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
            JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2001
        ) AS overall_avg_profit
    FROM aggregated a
)
SELECT
    rank,
    i_category,
    i_brand,
    brand_product,
    first_word,
    total_net_profit,
    sales_cnt,
    overall_avg_profit
FROM final
WHERE rank <= 100
ORDER BY rank
LIMIT 100
