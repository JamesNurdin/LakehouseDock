WITH sales_by_mode_year AS (
    SELECT
        sm.sm_ship_mode_id,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_code IN ('AIR', 'SEA')
      AND cs.cs_quantity > 2
      AND cs.cs_net_profit > 500
      AND ws.ws_net_paid > 1000
    GROUP BY sm.sm_ship_mode_id, d.d_year
)
SELECT
    sbmy.sm_ship_mode_id,
    sbmy.d_year,
    sbmy.catalog_sales_total,
    sbmy.web_sales_total,
    (sbmy.catalog_sales_total + sbmy.web_sales_total) AS total_sales,
    (sbmy.catalog_sales_total + sbmy.web_sales_total) / NULLIF(sbmy.catalog_orders + sbmy.web_orders, 0) AS avg_sale_per_order
FROM sales_by_mode_year sbmy
WHERE (sbmy.catalog_sales_total + sbmy.web_sales_total) > 20000
  AND (sbmy.catalog_sales_total + sbmy.web_sales_total) / NULLIF(sbmy.catalog_orders + sbmy.web_orders, 0) > 150
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs3
        JOIN tpcds.ship_mode sm2
            ON cs3.cs_ship_mode_sk = sm2.sm_ship_mode_sk
        WHERE sm2.sm_ship_mode_id = sbmy.sm_ship_mode_id
          AND cs3.cs_ext_ship_cost > 500
    )
ORDER BY total_sales DESC
LIMIT 100
