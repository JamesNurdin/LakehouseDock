WITH part1 AS (
    SELECT
        cs.cs_order_number AS order_number,
        cc.cc_name AS name,
        cs.cs_sales_price AS sales_price,
        cs.cs_net_profit AS net_profit,
        'call_center' AS source
    FROM catalog_sales cs
    FULL OUTER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_class = 'large'
      AND cs.cs_sales_price > 20
),
part2 AS (
    SELECT
        cs.cs_order_number AS order_number,
        sm.sm_carrier AS carrier,
        cs.cs_sales_price AS sales_price,
        cs.cs_net_profit AS net_profit,
        'ship_mode' AS source
    FROM catalog_sales cs
    FULL OUTER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract LIKE 'G%'
      AND cs.cs_sales_price BETWEEN 15 AND 30
)
SELECT
    ROW_NUMBER() OVER (ORDER BY order_number) AS row_num,
    order_number,
    name,
    carrier,
    sales_price,
    net_profit,
    source
FROM (
    SELECT
        order_number,
        name,
        NULL AS carrier,
        sales_price,
        net_profit,
        source
    FROM part1
    UNION ALL
    SELECT
        order_number,
        NULL AS name,
        carrier,
        sales_price,
        net_profit,
        source
    FROM part2
) t
ORDER BY row_num
LIMIT 100
