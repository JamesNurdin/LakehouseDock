WITH filtered AS (
    SELECT
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        cs.cs_net_profit,
        ws.ws_net_profit,
        cs.cs_order_number,
        ws.ws_order_number,
        sm.sm_ship_mode_id,
        sm.sm_type,
        td.t_hour,
        td.t_minute,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cs.cs_ship_date_sk,
        sm.sm_ship_mode_sk
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450840 AND 2450900
      AND cd.cd_gender = 'F'
      AND cd.cd_purchase_estimate >= 5000
      AND td.t_minute IN (12, 13, 14, 15, 16)
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
            AND ws2.ws_coupon_amt > 500
      )
),
agg AS (
    SELECT
        sm_ship_mode_id,
        t_hour,
        cd_gender,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_net_profit + ws_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws_order_number) AS web_orders
    FROM filtered
    GROUP BY sm_ship_mode_id, t_hour, cd_gender
)
SELECT
    sm_ship_mode_id,
    t_hour,
    cd_gender,
    total_catalog_sales,
    total_web_sales,
    total_profit,
    catalog_orders,
    web_orders,
    SUM(total_catalog_sales) OVER (
        PARTITION BY sm_ship_mode_id
        ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_catalog_sales
FROM agg
ORDER BY total_profit DESC
LIMIT 100
