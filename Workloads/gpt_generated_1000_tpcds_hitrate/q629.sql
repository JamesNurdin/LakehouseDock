WITH store_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY CUBE (d.d_year, i.i_category, p.p_promo_name)
),
web_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        p.p_promo_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS sales_amount,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_qty
    FROM web_sales ws
    RIGHT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    )
    GROUP BY CUBE (d.d_year, i.i_category, p.p_promo_name)
)
SELECT
    combined.d_year,
    combined.i_category,
    combined.p_promo_name,
    combined.sales_amount,
    combined.total_qty,
    LAG(combined.sales_amount) OVER (PARTITION BY combined.d_year ORDER BY combined.i_category) AS lag_sales_amount
FROM (
    SELECT d_year, i_category, p_promo_name, sales_amount, total_qty
    FROM store_agg
    UNION ALL
    SELECT d_year, i_category, p_promo_name, sales_amount, total_qty
    FROM web_agg
) AS combined
ORDER BY combined.d_year DESC, combined.sales_amount DESC
LIMIT 100
