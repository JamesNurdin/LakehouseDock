/* Goal: Compare daily total sales for catalog and web channels by item, exclude items currently under an active promotion, and enrich each row with the sum of all historical promotion costs for that item. */
WITH catalog AS (
    SELECT
        d.d_date AS sales_date,
        i.i_item_sk,
        i.i_item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY d.d_date, i.i_item_sk, i.i_item_id
),
web AS (
    SELECT
        d.d_date AS sales_date,
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY d.d_date, i.i_item_sk, i.i_item_id
),
union_sales AS (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
),
filtered AS (
    SELECT *
    FROM union_sales us
    WHERE us.i_item_sk NOT IN (
        SELECT p_item_sk FROM promotion WHERE p_discount_active = 'Y'
    )
)
SELECT
    fs.sales_date,
    fs.i_item_id,
    fs.total_sales,
    fs.order_cnt,
    promo_sum.promo_cost_total
FROM filtered fs
CROSS JOIN LATERAL (
    SELECT COALESCE(SUM(p.p_cost), 0) AS promo_cost_total
    FROM promotion p
    WHERE p.p_item_sk = fs.i_item_sk
) AS promo_sum
ORDER BY fs.sales_date DESC, fs.total_sales DESC
LIMIT 100
