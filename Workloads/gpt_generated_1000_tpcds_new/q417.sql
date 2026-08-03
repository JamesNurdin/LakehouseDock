WITH
store_return_agg AS (
    SELECT
        s.s_state AS store_state,
        d.d_year AS year,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt,
        AVG(la.loss_per_item) AS avg_loss_per_item
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT sr.sr_net_loss / NULLIF(sr.sr_return_quantity, 0) AS loss_per_item
    ) AS la
    GROUP BY ROLLUP (s.s_state, d.d_year)
),
sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY ROLLUP (cc.cc_name, d.d_year)
),
common_years AS (
    SELECT year FROM (
        SELECT DISTINCT year FROM store_return_agg WHERE year IS NOT NULL
    )
    INTERSECT
    SELECT year FROM (
        SELECT DISTINCT year FROM sales_agg WHERE year IS NOT NULL
    )
),
web_return_agg AS (
    SELECT
        d.d_year AS year,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
combined_years AS (
    SELECT year FROM common_years
    UNION
    SELECT year FROM web_return_agg
)
SELECT
    COALESCE(sr.store_state, 'ALL_STATES') AS store_state,
    COALESCE(sa.call_center_name, 'ALL_CC') AS call_center_name,
    cy.year,
    sr.store_net_loss,
    sr.store_return_cnt,
    sr.avg_loss_per_item,
    sa.total_sales,
    sa.sales_cnt,
    wr.web_net_loss,
    wr.web_return_cnt
FROM combined_years cy
FULL OUTER JOIN store_return_agg sr
    ON cy.year = sr.year
FULL OUTER JOIN sales_agg sa
    ON cy.year = sa.year
FULL OUTER JOIN web_return_agg wr
    ON cy.year = wr.year
ORDER BY
    store_state,
    call_center_name,
    cy.year
