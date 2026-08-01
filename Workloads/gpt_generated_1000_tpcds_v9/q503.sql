WITH sales_agg AS (
    SELECT
        cs_bill_hdemo_sk,
        SUM(cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM
        catalog_sales
    WHERE
        cs_ext_list_price > 2000
        AND cs_quantity >= 2
    GROUP BY
        cs_bill_hdemo_sk
    HAVING
        SUM(cs_net_paid_inc_ship_tax) > 1000
)
SELECT
    hd.hd_demo_sk,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    CASE
        WHEN hd.hd_vehicle_count > 2 THEN 'Many'
        WHEN hd.hd_vehicle_count = 0 THEN 'None'
        ELSE 'Few'
    END AS vehicle_category,
    sales_agg.total_quantity,
    sales_agg.total_net_paid_inc_ship_tax,
    sales_agg.total_net_profit,
    RANK() OVER (ORDER BY sales_agg.total_net_profit DESC) AS profit_rank,
    SUM(sales_agg.total_net_profit) OVER (
        ORDER BY sales_agg.total_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM
    sales_agg
JOIN
    household_demographics AS hd
    ON sales_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE
    hd.hd_dep_count >= 1
ORDER BY
    profit_rank
LIMIT 100
