WITH
-- Aggregate store sales with an anti‑join to web_returns
store_agg AS (
    SELECT
        ss.ss_store_sk AS entity_id,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS metric_value,
        'Profit' AS metric_type,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS status,
        LAG(SUM(ss.ss_net_profit)) OVER (PARTITION BY ss.ss_store_sk ORDER BY d.d_year) AS lag_metric,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_profit) DESC) AS rnk
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_returned_date_sk = ss.ss_sold_date_sk
              AND wr.wr_item_sk = ss.ss_item_sk
          )
      AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY ss.ss_store_sk, d.d_year
),

-- Full outer join of promotions and catalog pages, then aggregate per year
promo_agg AS (
    SELECT
        COALESCE(p.p_promo_sk, -1) AS entity_id,
        d.d_year AS year,
        SUM(COALESCE(p.p_cost, 0)) AS metric_value,
        'PromoCost' AS metric_type,
        CASE WHEN COUNT(cp.cp_catalog_page_sk) > 0 THEN 'HasPage' ELSE 'NoPage' END AS status,
        LAG(SUM(COALESCE(p.p_cost, 0))) OVER (PARTITION BY COALESCE(p.p_promo_sk, -1) ORDER BY d.d_year) AS lag_metric,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(COALESCE(p.p_cost, 0)) DESC) AS rnk
    FROM promotion p
    FULL OUTER JOIN catalog_page cp
      ON p.p_promo_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d
      ON (p.p_start_date_sk = d.d_date_sk OR cp.cp_start_date_sk = d.d_date_sk)
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY COALESCE(p.p_promo_sk, -1), d.d_year
),

-- Scalar sub‑query used in both sides of the UNION
avg_promo_cost AS (
    SELECT AVG(p2.p_cost) AS avg_cost
    FROM promotion p2
)

SELECT
    s.entity_id,
    'Store' AS entity_type,
    s.year,
    s.metric_value,
    s.metric_type,
    s.status,
    s.lag_metric,
    s.rnk,
    a.avg_cost
FROM (
    SELECT * FROM store_agg WHERE rnk <= 5
) s
CROSS JOIN avg_promo_cost a

UNION ALL

SELECT
    p.entity_id,
    'PromoPage' AS entity_type,
    p.year,
    p.metric_value,
    p.metric_type,
    p.status,
    p.lag_metric,
    p.rnk,
    a.avg_cost
FROM (
    SELECT * FROM promo_agg WHERE rnk <= 5
) p
CROSS JOIN avg_promo_cost a

ORDER BY entity_type, year, metric_value DESC
LIMIT 100
