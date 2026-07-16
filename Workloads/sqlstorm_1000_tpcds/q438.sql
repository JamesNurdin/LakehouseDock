WITH
date_lookup AS (
    SELECT d_date_sk,
           substr(cast(d_date AS varchar), 1, 7) AS year_month
    FROM date_dim
),
item_lookup AS (
    SELECT i_item_sk,
           i_category
    FROM item
),
promo_active AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
),
cs_agg AS (
    SELECT
        dl.year_month,
        il.i_category,
        SUM(cs.cs_net_profit) AS cs_net_profit,
        SUM(cs.cs_quantity) AS cs_quantity,
        AVG(cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0)) AS cs_avg_discount_rate,
        SUM(cs.cs_net_paid) AS cs_net_paid
    FROM catalog_sales cs
    JOIN date_lookup dl ON cs.cs_sold_date_sk = dl.d_date_sk
    JOIN item_lookup il ON cs.cs_item_sk = il.i_item_sk
    LEFT JOIN promo_active pa ON cs.cs_promo_sk = pa.p_promo_sk
    GROUP BY dl.year_month, il.i_category
),
ss_agg AS (
    SELECT
        dl.year_month,
        il.i_category,
        SUM(ss.ss_net_profit) AS ss_net_profit,
        SUM(ss.ss_quantity) AS ss_quantity,
        AVG(ss.ss_ext_discount_amt / NULLIF(ss.ss_ext_sales_price, 0)) AS ss_avg_discount_rate,
        SUM(ss.ss_net_paid) AS ss_net_paid
    FROM store_sales ss
    JOIN date_lookup dl ON ss.ss_sold_date_sk = dl.d_date_sk
    JOIN item_lookup il ON ss.ss_item_sk = il.i_item_sk
    LEFT JOIN promo_active pa ON ss.ss_promo_sk = pa.p_promo_sk
    GROUP BY dl.year_month, il.i_category
),
ws_agg AS (
    SELECT
        dl.year_month,
        il.i_category,
        SUM(ws.ws_net_profit) AS ws_net_profit,
        SUM(ws.ws_quantity) AS ws_quantity,
        AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS ws_avg_discount_rate,
        SUM(ws.ws_net_paid) AS ws_net_paid
    FROM web_sales ws
    JOIN date_lookup dl ON ws.ws_sold_date_sk = dl.d_date_sk
    JOIN item_lookup il ON ws.ws_item_sk = il.i_item_sk
    LEFT JOIN promo_active pa ON ws.ws_promo_sk = pa.p_promo_sk
    GROUP BY dl.year_month, il.i_category
),
combined AS (
    SELECT
        COALESCE(cs.year_month, ss.year_month, ws.year_month) AS year_month,
        COALESCE(cs.i_category, ss.i_category, ws.i_category) AS i_category,
        cs.cs_net_profit,
        ss.ss_net_profit,
        ws.ws_net_profit,
        cs.cs_quantity,
        ss.ss_quantity,
        ws.ws_quantity,
        cs.cs_avg_discount_rate,
        ss.ss_avg_discount_rate,
        ws.ws_avg_discount_rate,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid
    FROM cs_agg cs
    FULL OUTER JOIN ss_agg ss ON cs.year_month = ss.year_month AND cs.i_category = ss.i_category
    FULL OUTER JOIN ws_agg ws ON COALESCE(cs.year_month, ss.year_month) = ws.year_month AND COALESCE(cs.i_category, ss.i_category) = ws.i_category
),
totals AS (
    SELECT
        year_month,
        i_category,
        cs_net_profit,
        ss_net_profit,
        ws_net_profit,
        COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0) AS total_net_profit,
        cs_quantity,
        ss_quantity,
        ws_quantity,
        COALESCE(cs_quantity, 0) + COALESCE(ss_quantity, 0) + COALESCE(ws_quantity, 0) AS total_quantity,
        cs_avg_discount_rate,
        ss_avg_discount_rate,
        ws_avg_discount_rate,
        (COALESCE(cs_avg_discount_rate, 0) * COALESCE(cs_quantity, 0) + COALESCE(ss_avg_discount_rate, 0) * COALESCE(ss_quantity, 0) + COALESCE(ws_avg_discount_rate, 0) * COALESCE(ws_quantity, 0))
            / NULLIF(COALESCE(cs_quantity, 0) + COALESCE(ss_quantity, 0) + COALESCE(ws_quantity, 0), 0) AS weighted_avg_discount_rate,
        cs_net_paid,
        ss_net_paid,
        ws_net_paid,
        COALESCE(cs_net_paid, 0) + COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0) AS total_net_paid
    FROM combined
),
ranked AS (
    SELECT
        *,
        LAG(total_net_profit) OVER (PARTITION BY i_category ORDER BY year_month) AS prev_total_net_profit,
        RANK() OVER (PARTITION BY year_month ORDER BY total_net_profit DESC) AS category_rank_in_month
    FROM totals
)
SELECT
    year_month,
    i_category,
    cs_net_profit,
    ss_net_profit,
    ws_net_profit,
    total_net_profit,
    cs_quantity,
    ss_quantity,
    ws_quantity,
    total_quantity,
    cs_avg_discount_rate,
    ss_avg_discount_rate,
    ws_avg_discount_rate,
    weighted_avg_discount_rate,
    cs_net_paid,
    ss_net_paid,
    ws_net_paid,
    total_net_paid,
    CASE WHEN prev_total_net_profit IS NOT NULL AND prev_total_net_profit <> 0
         THEN (total_net_profit / prev_total_net_profit) - 1
         ELSE NULL END AS yoy_net_profit_change,
    category_rank_in_month
FROM ranked
WHERE i_category IS NOT NULL
  AND category_rank_in_month <= 10
ORDER BY year_month, category_rank_in_month
