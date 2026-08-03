WITH base AS (
    SELECT
        w.w_state,
        sm.sm_carrier,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        lt.total_qty
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT SUM(cs2.cs_quantity) AS total_qty
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = cs.cs_warehouse_sk
    ) lt ON true
    WHERE w.w_country = 'United States'
      AND w.w_county = 'Marshall County'
      AND sm.sm_carrier = 'AIRBORNE'
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_coupon_amt < 500
      AND EXISTS (
            SELECT 1 FROM catalog_sales cs3
            WHERE cs3.cs_warehouse_sk = cs.cs_warehouse_sk
              AND cs3.cs_net_profit > cs.cs_net_profit
        )
    UNION
    SELECT
        w.w_state,
        sm.sm_carrier,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        lt.total_qty
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT SUM(cs2.cs_quantity) AS total_qty
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = cs.cs_warehouse_sk
    ) lt ON true
    WHERE w.w_country = 'United States'
      AND w.w_county = 'San Miguel County'
      AND sm.sm_carrier = 'GERMA'
      AND cs.cs_ext_sales_price BETWEEN 500 AND 2000
      AND cs.cs_coupon_amt BETWEEN 0 AND 300
      AND EXISTS (
            SELECT 1 FROM catalog_sales cs3
            WHERE cs3.cs_warehouse_sk = cs.cs_warehouse_sk
              AND cs3.cs_net_profit > cs.cs_net_profit
        )
)
SELECT
    b.w_state,
    b.sm_carrier,
    b.profit_flag,
    SUM(b.cs_net_profit) AS total_net_profit,
    AVG(b.cs_ext_sales_price) AS avg_sales_price,
    SUM(b.cs_quantity) AS total_quantity,
    MIN(b.cs_ext_sales_price) AS min_sales_price,
    MAX(b.cs_ext_sales_price) AS max_sales_price,
    b.total_qty
FROM base b
GROUP BY b.w_state, b.sm_carrier, b.profit_flag, b.total_qty
HAVING SUM(b.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
