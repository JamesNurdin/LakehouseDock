WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy
),
store_returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_net_loss) AS total_store_returns_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        SUM(cr.cr_net_loss) AS total_catalog_returns_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    GROUP BY d.d_year, d.d_moy
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.d_year,
    s.d_moy,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_store_returns_loss, 0) AS total_store_returns_loss,
    COALESCE(c.total_catalog_returns_loss, 0) AS total_catalog_returns_loss,
    s.total_profit - COALESCE(r.total_store_returns_loss, 0) - COALESCE(c.total_catalog_returns_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN store_returns_agg r
    ON s.s_store_id = r.s_store_id
    AND s.d_year = r.d_year
    AND s.d_moy = r.d_moy
LEFT JOIN catalog_returns_agg c
    ON s.d_year = c.d_year
    AND s.d_moy = c.d_moy
ORDER BY s.d_year, s.d_moy, s.s_store_id
