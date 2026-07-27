WITH
    filtered_warehouses AS (
        SELECT w_warehouse_sk,
               w_warehouse_name,
               w_county
        FROM   warehouse
        WHERE  w_county IN ('Bronx County', 'Mobile County')
    ),
    return_agg AS (
        SELECT
            fw.w_warehouse_name,
            fw.w_county,
            'return' AS activity_type,
            SUM(cr.cr_return_amount) AS total_amount,
            COUNT(*) AS txn_count,
            (SELECT AVG(cr2.cr_return_amount)
               FROM catalog_returns cr2) AS avg_amount_overall
        FROM   catalog_returns cr
        JOIN   filtered_warehouses fw
               ON cr.cr_warehouse_sk = fw.w_warehouse_sk
        JOIN   reason r
               ON cr.cr_reason_sk = r.r_reason_sk
        WHERE  r.r_reason_desc = 'Package was damaged'
        GROUP BY fw.w_warehouse_name, fw.w_county
    ),
    sales_agg AS (
        SELECT
            fw.w_warehouse_name,
            fw.w_county,
            'sale' AS activity_type,
            SUM(ws.ws_ext_sales_price) AS total_amount,
            COUNT(*) AS txn_count,
            (SELECT AVG(ws2.ws_ext_sales_price)
               FROM web_sales ws2) AS avg_amount_overall
        FROM   web_sales ws
        JOIN   filtered_warehouses fw
               ON ws.ws_warehouse_sk = fw.w_warehouse_sk
        JOIN   household_demographics hd
               ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        WHERE  hd.hd_buy_potential = '>10000'
        GROUP BY fw.w_warehouse_name, fw.w_county
    )
SELECT
    activity_type,
    w_warehouse_name,
    w_county,
    total_amount,
    txn_count,
    avg_amount_overall,
    RANK() OVER (PARTITION BY activity_type ORDER BY total_amount DESC) AS activity_rank
FROM (
    SELECT * FROM return_agg
    UNION ALL
    SELECT * FROM sales_agg
) combined
ORDER BY activity_type, activity_rank
LIMIT 100
