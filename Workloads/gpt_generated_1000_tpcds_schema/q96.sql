WITH bill_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cd.cd_gender,
        'bill' AS source,
        (
            SELECT MAX(cs2.cs_ext_ship_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_ship_date_sk = cs.cs_ship_date_sk
        ) AS metric_val
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_count >= 2
      AND cd.cd_credit_rating = 'Excellent'
),
ship_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cd.cd_gender,
        'ship' AS source,
        cost_price_val AS metric_val
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN UNNEST(ARRAY[cs.cs_wholesale_cost, cs.cs_list_price]) AS t(cost_price_val)
    WHERE cd.cd_dep_employed_count >= 1
      AND cd.cd_credit_rating = 'Good'
)
SELECT
    cs_order_number,
    cs_net_profit,
    cd_gender,
    source,
    metric_val
FROM bill_sales
UNION ALL
SELECT
    cs_order_number,
    cs_net_profit,
    cd_gender,
    source,
    metric_val
FROM ship_sales
LIMIT 100
