WITH sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk,
        NULL AS store_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        ss.ss_store_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        NULL
    FROM web_sales ws
),
returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        -cr.cr_return_quantity AS quantity,
        -cr.cr_return_amount AS net_paid,
        -cr.cr_net_loss AS net_profit,
        NULL AS promo_sk,
        NULL AS store_sk
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        -sr.sr_return_quantity,
        -sr.sr_return_amt,
        -sr.sr_net_loss,
        NULL,
        sr.sr_store_sk
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        -wr.wr_return_quantity,
        -wr.wr_return_amt,
        -wr.wr_net_loss,
        NULL,
        NULL
    FROM web_returns wr
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
),
promo_agg AS (
    SELECT
        p.p_promo_sk,
        SUM(p.p_cost) AS total_promo_cost,
        MAX(p.p_discount_active) AS discount_active_flag
    FROM promotion p
    GROUP BY p.p_promo_sk
),
aggregated AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(c.net_paid) AS total_net_paid,
        SUM(c.net_profit) AS total_net_profit,
        COUNT(DISTINCT c.item_sk) AS distinct_items_sold,
        SUM(COALESCE(pa.total_promo_cost, 0)) AS total_promo_cost
    FROM combined c
    JOIN date_dim d ON c.date_sk = d.d_date_sk
    JOIN item i ON c.item_sk = i.i_item_sk
    LEFT JOIN promo_agg pa ON c.promo_sk = pa.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category, i.i_brand
    HAVING SUM(c.net_paid) > 1000000
)
SELECT
    d_year,
    i_category,
    i_brand,
    ROUND(CASE WHEN total_net_paid = 0 THEN 0 ELSE total_net_profit / total_net_paid END, 4) AS profit_margin,
    total_net_paid,
    total_net_profit,
    distinct_items_sold,
    total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, profit_rank
LIMIT 100
