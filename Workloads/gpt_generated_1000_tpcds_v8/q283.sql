WITH catalog_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(w.w_warehouse_name, '^A')
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city
),
web_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_name LIKE '%Warehouse%'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city
),
sales_union AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city,
        catalog_sales_amount AS sales_amount,
        catalog_profit AS profit,
        'catalog' AS source
    FROM catalog_sales_agg
    UNION DISTINCT
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city,
        web_sales_amount AS sales_amount,
        web_profit AS profit,
        'web' AS source
    FROM web_sales_agg
),
returns_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        regexp_extract(r.r_reason_desc, '(\\w+)$', 1) AS reason_last_word,
        CASE
            WHEN r.r_reason_desc LIKE '%size%' THEN 'Size Issue'
            WHEN regexp_like(r.r_reason_desc, '.*model.*') THEN 'Model Issue'
            ELSE 'Other'
        END AS reason_category
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city,
        regexp_extract(r.r_reason_desc, '(\\w+)$', 1),
        CASE
            WHEN r.r_reason_desc LIKE '%size%' THEN 'Size Issue'
            WHEN regexp_like(r.r_reason_desc, '.*model.*') THEN 'Model Issue'
            ELSE 'Other'
        END
)
SELECT
    COALESCE(s.w_warehouse_name, r.w_warehouse_name) AS warehouse_name,
    COALESCE(s.w_city, r.w_city) AS city,
    CONCAT(COALESCE(s.w_warehouse_name, r.w_warehouse_name), ' - ', COALESCE(s.w_city, r.w_city)) AS warehouse_full_name,
    s.source,
    s.sales_amount,
    s.profit,
    r.total_return_amount,
    r.return_cnt,
    r.reason_last_word,
    r.reason_category,
    CASE
        WHEN s.sales_amount > 10000 THEN 'High Sales'
        WHEN s.sales_amount IS NULL THEN 'No Sales'
        ELSE 'Low Sales'
    END AS sales_level
FROM sales_union s
FULL OUTER JOIN returns_agg r
    ON s.w_warehouse_sk = r.w_warehouse_sk
ORDER BY warehouse_name
LIMIT 100
