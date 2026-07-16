WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS cs_profit,
        SUM(cs.cs_net_paid) AS cs_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year >= 1998
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS ss_profit,
        SUM(ss.ss_net_paid) AS ss_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year >= 1998
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS ws_profit,
        SUM(ws.ws_net_paid) AS ws_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year >= 1998
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.i_category,
        COALESCE(cs.cs_profit, 0) + COALESCE(ss.ss_profit, 0) + COALESCE(ws.ws_profit, 0) AS total_profit,
        COALESCE(cs.cs_paid, 0) + COALESCE(ss.ss_paid, 0) + COALESCE(ws.ws_paid, 0) AS total_paid
    FROM (
        SELECT DISTINCT d_year, d_month_seq, i_category
        FROM (
            SELECT d_year, d_month_seq, i_category FROM catalog_sales_agg
            UNION ALL
            SELECT d_year, d_month_seq, i_category FROM store_sales_agg
            UNION ALL
            SELECT d_year, d_month_seq, i_category FROM web_sales_agg
        ) u
    ) s
    LEFT JOIN catalog_sales_agg cs ON s.d_year = cs.d_year AND s.d_month_seq = cs.d_month_seq AND s.i_category = cs.i_category
    LEFT JOIN store_sales_agg ss ON s.d_year = ss.d_year AND s.d_month_seq = ss.d_month_seq AND s.i_category = ss.i_category
    LEFT JOIN web_sales_agg ws ON s.d_year = ws.d_year AND s.d_month_seq = ws.d_month_seq AND s.i_category = ws.i_category
),
profit_growth AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        total_profit,
        LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq) AS prev_profit,
        (total_profit - LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq))
          / NULLIF(LAG(total_profit) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq), 0) AS mom_growth
    FROM combined
),
avg_growth AS (
    SELECT
        d_year,
        i_category,
        AVG(mom_growth) AS avg_mom_growth
    FROM profit_growth
    WHERE mom_growth IS NOT NULL
    GROUP BY d_year, i_category
),
ranked_growth AS (
    SELECT
        d_year,
        i_category,
        avg_mom_growth,
        RANK() OVER (PARTITION BY d_year ORDER BY avg_mom_growth DESC) AS growth_rank
    FROM avg_growth
)
SELECT
    d_year,
    i_category,
    avg_mom_growth,
    growth_rank
FROM ranked_growth
WHERE growth_rank <= 10
ORDER BY d_year, growth_rank
