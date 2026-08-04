WITH
sales_ship AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_net_profit,
        sm.sm_carrier,
        sm.sm_type,
        sm.sm_contract
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(sm.sm_carrier, '^U[PS]{2}$')
      AND sm.sm_type LIKE '%DAY%'
),
returned_orders AS (
    SELECT DISTINCT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract LIKE 'P%8'
),
orders_without_return AS (
    SELECT cs_order_number
    FROM sales_ship
    EXCEPT
    SELECT order_number FROM returned_orders
)
SELECT
    dw.d_year,
    s.sm_carrier,
    COUNT(DISTINCT s.cs_order_number) AS orders_cnt,
    SUM(s.cs_sales_price) AS total_sales,
    CONCAT('Carrier ', s.sm_carrier) AS carrier_label,
    lc.contract_suffix
FROM sales_ship s
JOIN date_dim dw
    ON s.cs_sold_date_sk = dw.d_date_sk
JOIN orders_without_return owr
    ON s.cs_order_number = owr.cs_order_number
CROSS JOIN LATERAL (
    SELECT regexp_extract(s.sm_contract, '(\\d+)$') AS contract_suffix
) lc
GROUP BY
    dw.d_year,
    s.sm_carrier,
    lc.contract_suffix
ORDER BY total_sales DESC
LIMIT 100
