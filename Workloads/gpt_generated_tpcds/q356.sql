WITH store_discount AS (
    SELECT
        p.p_promo_name AS promo_name,
        i.i_category   AS category,
        d.d_year       AS year,
        SUM(ss.ss_ext_discount_amt) AS discount_amount
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY p.p_promo_name, i.i_category, d.d_year
),
web_discount AS (
    SELECT
        p.p_promo_name AS promo_name,
        i.i_category   AS category,
        d.d_year       AS year,
        SUM(ws.ws_ext_discount_amt) AS discount_amount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY p.p_promo_name, i.i_category, d.d_year
),
combined AS (
    SELECT promo_name, category, year, discount_amount FROM store_discount
    UNION ALL
    SELECT promo_name, category, year, discount_amount FROM web_discount
)
SELECT
    promo_name,
    category,
    year,
    SUM(discount_amount) AS total_discount_amount
FROM combined
GROUP BY promo_name, category, year
ORDER BY total_discount_amount DESC
LIMIT 10
