/*
Goal: Compare the sales performance of shipping modes across the catalog_sales and web_sales facts, ranking each mode by total sales, limiting to the top 100 rows, and excluding any shipping mode with a specific excluded code.
*/
WITH catalog_agg AS (
    SELECT
        cs.cs_ship_mode_sk            AS ship_mode_sk,
        sm.sm_ship_mode_id            AS ship_mode_id,
        SUM(cs.cs_ext_sales_price)    AS total_sales,
        AVG(cs.cs_ext_discount_amt)   AS avg_discount,
        COUNT(*)                      AS order_cnt,
        RANK() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM
        catalog_sales cs
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        cs.cs_ship_date_sk BETWEEN 2450846 AND 2450904               -- filter 1 (date surrogate key range)
        AND cs.cs_ext_wholesale_cost > 1000                         -- filter 2 (high wholesale cost)
        AND sm.sm_type = 'AIR'                                      -- filter 3 (ship mode type)
    GROUP BY
        cs.cs_ship_mode_sk,
        sm.sm_ship_mode_id
),
web_agg AS (
    SELECT
        ws.ws_ship_mode_sk            AS ship_mode_sk,
        sm.sm_ship_mode_id            AS ship_mode_id,
        ws.ws_web_site_sk             AS web_site_sk,
        ws_site.web_name              AS web_site_name,
        SUM(ws.ws_ext_sales_price)    AS total_sales,
        AVG(ws.ws_ext_discount_amt)   AS avg_discount,
        COUNT(*)                      AS order_cnt,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
        JOIN ship_mode sm   ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        ws.ws_wholesale_cost > 30                                 -- filter 4 (wholesale cost)
        AND ws.ws_ext_ship_cost < 3000                            -- filter 5 (ship cost)
        AND ws_site.web_county = 'Barrow County'                  -- filter 6 (county)
    GROUP BY
        ws.ws_ship_mode_sk,
        sm.sm_ship_mode_id,
        ws.ws_web_site_sk,
        ws_site.web_name
)
SELECT
    ship_mode_sk,
    ship_mode_id,
    total_sales,
    avg_discount,
    order_cnt,
    sales_rank,
    web_site_name,
    source
FROM (
    SELECT
        ship_mode_sk,
        ship_mode_id,
        total_sales,
        avg_discount,
        order_cnt,
        sales_rank,
        CAST(NULL AS VARCHAR)        AS web_site_name,
        'catalog'                     AS source
    FROM catalog_agg

    UNION ALL

    SELECT
        ship_mode_sk,
        ship_mode_id,
        total_sales,
        avg_discount,
        order_cnt,
        sales_rank,
        web_site_name,
        'web'                         AS source
    FROM web_agg
) combined
WHERE NOT EXISTS (
    SELECT 1
    FROM ship_mode sm_excl
    WHERE sm_excl.sm_ship_mode_sk = combined.ship_mode_sk
      AND sm_excl.sm_code = 'EXCLUDED_CODE'   -- anti‑join: drop excluded shipping codes
)
ORDER BY total_sales DESC
LIMIT 100
