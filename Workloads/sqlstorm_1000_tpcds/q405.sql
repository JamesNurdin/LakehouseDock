WITH
sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_net_paid
    FROM store_sales ss
),
joined_data AS (
    SELECT
        d.d_year,
        s.s_state,
        p.p_promo_name,
        i.i_category,
        sd.ss_net_profit,
        sd.ss_net_paid
    FROM sales_data sd
    JOIN date_dim d ON sd.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON sd.ss_store_sk = s.s_store_sk
    JOIN promotion p ON sd.ss_promo_sk = p.p_promo_sk
    JOIN item i ON sd.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state IS NOT NULL
),
agg_sales AS (
    SELECT
        d_year,
        s_state,
        p_promo_name,
        i_category,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_net_paid) AS total_paid
    FROM joined_data
    GROUP BY d_year, s_state, p_promo_name, i_category
),
ranked_sales AS (
    SELECT
        d_year,
        s_state,
        p_promo_name,
        i_category,
        total_profit,
        total_paid,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS promo_rank
    FROM agg_sales
)
SELECT
    d_year,
    s_state,
    p_promo_name,
    i_category,
    total_profit,
    total_paid,
    promo_rank
FROM ranked_sales
WHERE promo_rank <= 5
ORDER BY s_state, total_profit DESC
