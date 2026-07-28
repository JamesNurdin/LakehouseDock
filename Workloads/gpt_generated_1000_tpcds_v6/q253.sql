-- goal: Analyze return performance by promotion and catalog page type for a specific year, department, and county, showing aggregated metrics and a cumulative return amount per state.
WITH distinct_page_types AS (
    SELECT DISTINCT cp_type
    FROM catalog_page
    WHERE cp_department = 'Electronics'
),
base AS (
    SELECT
        wr.wr_return_tax,
        wr.wr_return_amt,
        wr.wr_order_number,
        cp.cp_type,
        cp.cp_department,
        p.p_promo_name,
        p.p_discount_active,
        ws.web_site_id,
        ws.web_state,
        ws.web_county,
        d.d_year
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                    -- filter 1: year
      AND p.p_discount_active = 'Y'                         -- filter 2: active promotions
      AND ws.web_county = 'Bronx County'                    -- filter 3: specific county
      AND wr.wr_return_tax > 15.00                          -- filter 4: return tax threshold
      AND cp.cp_type IN (SELECT cp_type FROM distinct_page_types) -- use DISTINCT list
),
promo_agg AS (
    SELECT
        p.p_promo_name AS category,
        'Promotion'      AS category_type,
        ws.web_state     AS state,
        COUNT(DISTINCT b.wr_order_number) AS return_count,
        SUM(b.wr_return_amt)              AS total_return_amt,
        AVG(b.wr_return_tax)              AS avg_return_tax
    FROM base b
    JOIN promotion p   ON p.p_promo_name = b.p_promo_name
    JOIN web_site ws   ON ws.web_site_id = b.web_site_id
    GROUP BY p.p_promo_name, ws.web_state
),
page_agg AS (
    SELECT
        cp.cp_type      AS category,
        'CatalogPage'   AS category_type,
        ws.web_state    AS state,
        COUNT(DISTINCT b.wr_order_number) AS return_count,
        SUM(b.wr_return_amt)              AS total_return_amt,
        AVG(b.wr_return_tax)              AS avg_return_tax
    FROM base b
    JOIN catalog_page cp ON cp.cp_type = b.cp_type
    JOIN web_site ws    ON ws.web_site_id = b.web_site_id
    GROUP BY cp.cp_type, ws.web_state
)
SELECT
    u.category,
    u.category_type,
    u.state,
    u.return_count,
    u.total_return_amt,
    u.avg_return_tax,
    SUM(u.total_return_amt) OVER (
        PARTITION BY u.state
        ORDER BY u.total_return_amt DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_state_return
FROM (
    SELECT * FROM promo_agg
    UNION ALL
    SELECT * FROM page_agg
) AS u
ORDER BY u.total_return_amt DESC
LIMIT 100
