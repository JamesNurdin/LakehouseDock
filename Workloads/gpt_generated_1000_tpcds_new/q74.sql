WITH sales_by_mode AS (
    SELECT
        sm.sm_type,
        sm.sm_contract,
        COUNT(ws.ws_order_number)            AS order_cnt,
        SUM(ws.ws_ext_sales_price)           AS total_sales,
        SUM(ws.ws_net_profit)                AS total_profit,
        AVG(ws.ws_list_price)                AS avg_list_price
    FROM
        web_sales ws
    RIGHT OUTER JOIN
        ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        ws.ws_list_price > 50.00
        AND ws.ws_quantity BETWEEN 1 AND 5
        AND ws.ws_ext_discount_amt < 200.00
        AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT', 'TWO DAY')
        AND sm.sm_contract LIKE '%Z%'
    GROUP BY
        sm.sm_type,
        sm.sm_contract
    HAVING
        SUM(ws.ws_ext_sales_price) > 5000.00
),
ranked_sales AS (
    SELECT
        sm_type,
        sm_contract,
        order_cnt,
        total_sales,
        total_profit,
        avg_list_price,
        ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS rnk
    FROM sales_by_mode
)
SELECT
    sm_type,
    sm_contract,
    order_cnt,
    total_sales,
    total_profit,
    avg_list_price,
    rnk
FROM ranked_sales
WHERE rnk <= 3
ORDER BY sm_type, rnk
LIMIT 100
