WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_product_name, '^.*[0-9]{3}.*$')
      AND i.i_item_desc LIKE '%BRIGHT%'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, w.w_warehouse_id, sm.sm_ship_mode_id
)
SELECT
    s.i_item_id,
    s.i_product_name,
    s.w_warehouse_id,
    s.sm_ship_mode_id,
    s.total_sales,
    s.total_profit,
    s.sales_cnt,
    regexp_extract(s.i_product_name, '(\\d{3})', 1) AS product_code,
    (
        SELECT AVG(wr.wr_return_amt)
        FROM web_returns wr
        WHERE wr.wr_item_sk = s.i_item_sk
    ) AS avg_return_amt,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_item_sk = s.i_item_sk
              AND wr2.wr_return_amt > 100
        ) THEN 'HighReturn'
        ELSE 'Normal'
    END AS return_flag
FROM sales_agg s
WHERE s.total_sales > 10000
ORDER BY s.total_sales DESC
LIMIT 100
