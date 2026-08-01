WITH ws_warehouse AS (
    SELECT
        ws_warehouse_sk,
        ws_item_sk,
        ws_net_paid_inc_ship,
        ws_net_profit,
        ws_quantity
    FROM web_sales
    WHERE ws_net_paid_inc_ship > 2000
      AND ws_quantity >= 1
      AND ws_net_profit <> 0
      AND ws_warehouse_sk IN (
          SELECT w_warehouse_sk
          FROM warehouse
          WHERE w_warehouse_sq_ft > 500000
            AND w_country = 'United States'
      )
      AND EXISTS (
          SELECT 1
          FROM warehouse w_city
          WHERE w_city.w_warehouse_sk = web_sales.ws_warehouse_sk
            AND w_city.w_city = 'Seattle'
      )
),
wh_filtered AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_warehouse_sq_ft,
        w_city
    FROM warehouse
    WHERE w_warehouse_sq_ft BETWEEN 600000 AND 800000
      AND w_country = 'United States'
),
joined_full AS (
    SELECT
        COALESCE(ws.ws_warehouse_sk, wh.w_warehouse_sk) AS warehouse_sk,
        ws.ws_item_sk,
        wh.w_warehouse_name,
        ws.ws_net_paid_inc_ship,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM ws_warehouse ws
    FULL OUTER JOIN wh_filtered wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
),
agg1 AS (
    SELECT
        warehouse_sk,
        w_warehouse_name,
        SUM(ws_net_paid_inc_ship) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS cnt_transactions
    FROM joined_full
    GROUP BY GROUPING SETS (
        (warehouse_sk, w_warehouse_name),
        (warehouse_sk),
        ()
    )
),
agg2 AS (
    SELECT
        warehouse_sk,
        AVG(total_sales) AS avg_sales_per_group
    FROM agg1
    WHERE total_sales IS NOT NULL
    GROUP BY warehouse_sk
),
final AS (
    SELECT
        a.warehouse_sk,
        a.w_warehouse_name,
        a.total_sales,
        a.total_profit,
        a.cnt_transactions,
        b.avg_sales_per_group,
        SUM(a.total_sales) OVER (PARTITION BY a.w_warehouse_name) AS sales_by_name,
        RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank,
        (SELECT MAX(w_warehouse_sq_ft) FROM warehouse) AS max_warehouse_sq_ft
    FROM agg1 a
    LEFT JOIN agg2 b
        ON a.warehouse_sk = b.warehouse_sk
    WHERE a.total_sales > 5000
)

SELECT *
FROM final
WHERE warehouse_sk IN (
    SELECT warehouse_sk FROM agg1
    INTERSECT
    SELECT warehouse_sk FROM agg2
)

UNION

SELECT *
FROM final
WHERE warehouse_sk NOT IN (
    SELECT warehouse_sk FROM agg1
    INTERSECT
    SELECT warehouse_sk FROM agg2
)

LIMIT 100
