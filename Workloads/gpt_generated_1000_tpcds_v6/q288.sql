/*
Goal: Identify high‑profit web sales items for web sites whose company name contains 'pri', where the item brand matches a specific pattern. The query aggregates sales per item and site, filters sites by total profit, enriches the result with brand‑color concatenation, counts active promotions for each item, and orders by profit.
*/
WITH sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE regexp_like(i.i_brand, '^import.*scholar')
      AND wsite.web_company_name LIKE '%pri%'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY ws.ws_item_sk, ws.ws_web_site_sk
),
site_agg AS (
    SELECT
        ws_web_site_sk,
        SUM(total_profit) AS site_total_profit,
        SUM(total_sales) AS site_total_sales
    FROM sales_agg
    GROUP BY ws_web_site_sk
    HAVING SUM(total_profit) > 5000
)
SELECT
    s.ws_item_sk,
    i.i_product_name,
    wsite.web_name,
    s.total_sales,
    s.total_profit,
    CONCAT(i.i_brand, ' - ', i.i_color) AS brand_color,
    (
        SELECT COUNT(*)
        FROM promotion p
        WHERE p.p_item_sk = s.ws_item_sk
          AND p.p_discount_active = 'Y'
          AND EXISTS (
                SELECT 1
                FROM date_dim pd
                WHERE p.p_start_date_sk = pd.d_date_sk
                  AND pd.d_year = 2001
          )
    ) AS active_promo_cnt,
    sa.site_total_profit,
    sa.site_total_sales
FROM sales_agg s
JOIN site_agg sa ON s.ws_web_site_sk = sa.ws_web_site_sk
JOIN item i ON s.ws_item_sk = i.i_item_sk
JOIN web_site wsite ON s.ws_web_site_sk = wsite.web_site_sk
ORDER BY s.total_profit DESC
LIMIT 100
