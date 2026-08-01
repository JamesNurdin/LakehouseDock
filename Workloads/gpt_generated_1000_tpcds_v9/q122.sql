WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_size,
        sm.sm_ship_mode_sk,
        sm.sm_code,
        sm.sm_contract,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')
        AND i.i_size IN ('medium', 'small')
        AND ws.ws_quantity > 50
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        i.i_size,
        sm.sm_ship_mode_sk,
        sm.sm_code,
        sm.sm_contract
)
SELECT DISTINCT
    s.i_product_name,
    s.i_size,
    s.sm_code,
    s.sm_contract,
    s.total_sales,
    s.total_profit,
    s.order_count,
    s.avg_discount,
    CASE
        WHEN s.total_sales > (SELECT AVG(total_sales) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category,
    RANK() OVER (PARTITION BY s.sm_code ORDER BY s.total_sales DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY s.i_product_name ORDER BY s.total_profit DESC) AS profit_rownum
FROM sales_agg s
WHERE
    s.total_profit > 0
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = s.i_item_sk
          AND ws2.ws_wholesale_cost > 40
    )
ORDER BY s.sm_code, sales_rank
LIMIT 100
