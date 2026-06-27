WITH sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk AS catalog_page_sk,
        cs.cs_ship_mode_sk   AS ship_mode_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity)        AS total_quantity,
        SUM(cs.cs_net_profit)      AS total_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_catalog_page_sk, cs.cs_ship_mode_sk
),
returns_agg AS (
    SELECT
        cr.cr_catalog_page_sk AS catalog_page_sk,
        cr.cr_ship_mode_sk   AS ship_mode_sk,
        SUM(cr.cr_return_amount)   AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss)         AS total_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_catalog_page_sk, cr.cr_ship_mode_sk
)
SELECT
    cp.cp_catalog_page_number,
    cp.cp_department,
    sm.sm_type AS ship_mode,
    COALESCE(s.total_sales, 0)                         AS total_sales,
    COALESCE(r.total_return_amount, 0)                AS total_return_amount,
    COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amount, 0) AS net_sales,
    COALESCE(s.total_quantity, 0)                     AS total_quantity,
    COALESCE(r.total_return_quantity, 0)              AS total_return_quantity,
    CASE WHEN COALESCE(s.total_quantity, 0) = 0 THEN 0
         ELSE (COALESCE(r.total_return_quantity, 0) * 100.0 / COALESCE(s.total_quantity, 0))
    END                                               AS return_rate_percent,
    COALESCE(s.total_profit, 0) - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.catalog_page_sk = r.catalog_page_sk
   AND s.ship_mode_sk   = r.ship_mode_sk
LEFT JOIN catalog_page cp
    ON COALESCE(s.catalog_page_sk, r.catalog_page_sk) = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON COALESCE(s.ship_mode_sk, r.ship_mode_sk) = sm.sm_ship_mode_sk
ORDER BY net_sales DESC
LIMIT 100
