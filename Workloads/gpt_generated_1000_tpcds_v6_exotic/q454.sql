WITH ss_agg AS (
    SELECT
        s.s_store_id,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN "store" s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_ext_sales_price > 1000
    GROUP BY s.s_store_id, cd.cd_gender
    HAVING SUM(ss.ss_ext_sales_price) > 5000
),
ws_agg AS (
    SELECT
        w.w_warehouse_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_ext_sales_price > 500
    GROUP BY w.w_warehouse_id, cd.cd_gender
    HAVING COUNT(*) > 10
),
combined AS (
    SELECT
        'store'     AS source,
        s_store_id  AS id,
        cd_gender   AS gender,
        total_sales,
        sales_cnt,
        sales_rank
    FROM ss_agg
    UNION ALL
    SELECT
        'warehouse' AS source,
        w_warehouse_id AS id,
        cd_gender   AS gender,
        total_sales,
        sales_cnt,
        sales_rank
    FROM ws_agg
)
SELECT
    source,
    id,
    gender,
    total_sales,
    sales_cnt,
    sales_rank
FROM combined
WHERE sales_rank <= (
    SELECT MIN(sales_rank) FROM combined WHERE source = 'store'
)
ORDER BY total_sales DESC, source
LIMIT 100
