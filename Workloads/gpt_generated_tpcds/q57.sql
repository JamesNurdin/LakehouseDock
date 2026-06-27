WITH catalog_agg AS (
    SELECT
        d_cat.d_year,
        d_cat.d_moy,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_cat ON cs.cs_sold_date_sk = d_cat.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d_cat.d_year = 2001
    GROUP BY d_cat.d_year, d_cat.d_moy, p.p_promo_name
),
web_agg AS (
    SELECT
        d_web.d_year,
        d_web.d_moy,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d_web ON ws.ws_sold_date_sk = d_web.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d_web.d_year = 2001
    GROUP BY d_web.d_year, d_web.d_moy, p.p_promo_name
),
combined_sales AS (
    SELECT d_year, d_moy, p_promo_name, total_net_profit FROM catalog_agg
    UNION ALL
    SELECT d_year, d_moy, p_promo_name, total_net_profit FROM web_agg
),
sales_summary AS (
    SELECT
        d_year,
        d_moy,
        p_promo_name,
        SUM(total_net_profit) AS sum_net_profit
    FROM combined_sales
    GROUP BY d_year, d_moy, p_promo_name
),
returns_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_moy,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY d_ret.d_year, d_ret.d_moy
)
SELECT
    s.d_year,
    s.d_moy,
    s.p_promo_name,
    s.sum_net_profit,
    r.total_net_loss
FROM sales_summary s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year AND s.d_moy = r.d_moy
ORDER BY s.d_year, s.d_moy, s.sum_net_profit DESC
LIMIT 20
