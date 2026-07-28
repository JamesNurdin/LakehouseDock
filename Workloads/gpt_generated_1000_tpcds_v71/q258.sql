WITH joined_data AS (
    SELECT
        sm.sm_carrier,
        sm.sm_contract,
        sm.sm_type,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ws.ws_ext_sales_price            AS ws_sales_price,
        ws.ws_ext_ship_cost,
        ws.ws_ext_tax,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM tpcds.catalog_sales AS cs
    JOIN tpcds.ship_mode AS sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.catalog_returns AS cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales AS ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        cs.cs_ext_tax > 20
        AND ws.ws_ext_ship_cost < 1000
        AND sm.sm_carrier IN ('DIAMOND', 'TBS')
        AND sm.sm_contract LIKE 'U%'
        AND cs.cs_quantity BETWEEN 1 AND 10
        AND ws.ws_ext_tax BETWEEN 0 AND 300
        AND NOT EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns AS cr2
            WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
              AND cr2.cr_return_amount > 500
        )
)
SELECT
    sm_carrier,
    sm_contract,
    sm_type,
    COUNT(DISTINCT cs_bill_customer_sk)                     AS distinct_customers,
    SUM(cs_ext_sales_price)                                 AS total_catalog_sales,
    SUM(ws_sales_price)                                      AS total_web_sales,
    SUM(cr_return_amount)                                   AS total_return_amount,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (ORDER BY SUM(cs_ext_sales_price) DESC)    AS sales_rank,
    SUM(SUM(cs_ext_sales_price)) OVER (
        PARTITION BY sm_carrier
        ORDER BY sm_contract
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                       AS cum_sales_by_carrier
FROM joined_data
GROUP BY
    sm_carrier,
    sm_contract,
    sm_type
ORDER BY sales_rank
LIMIT 100
