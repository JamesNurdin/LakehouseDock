WITH max_year AS (
      SELECT MAX(d_year) AS yr FROM date_dim
    ),

    sales_data AS (
      SELECT
        'Sales' AS metric_type,
        CAST(dd.d_year AS VARCHAR) || '-' || CAST(dd.d_month_seq AS VARCHAR) AS period,
        SUM(ws.ws_net_profit) AS metric_value
      FROM web_sales ws
      JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
      JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
      WHERE dd.d_year = (SELECT yr FROM max_year)
        AND EXISTS (
          SELECT 1 FROM date_dim d2
          WHERE d2.d_date_sk = ws.ws_ship_date_sk
            AND d2.d_weekend = 'Y'
        )
      GROUP BY 1, 2
    ),

    inventory_data AS (
      SELECT
        'Inventory' AS metric_type,
        CAST(dd.d_year AS VARCHAR) || '-' || CAST(dd.d_month_seq AS VARCHAR) AS period,
        SUM(inv.inv_quantity_on_hand) AS metric_value
      FROM inventory inv
      JOIN date_dim dd ON inv.inv_date_sk = dd.d_date_sk
      WHERE dd.d_year = (SELECT yr FROM max_year)
        AND inv.inv_quantity_on_hand > (
          SELECT AVG(inv2.inv_quantity_on_hand)
          FROM inventory inv2
          WHERE inv2.inv_date_sk = inv.inv_date_sk
        )
      GROUP BY 1, 2
    ),

    combined AS (
      SELECT * FROM sales_data
      UNION ALL
      SELECT * FROM inventory_data
    )

SELECT
  metric_type,
  period,
  metric_value,
  CASE WHEN metric_value > 0 THEN 'Positive' ELSE 'Non-Positive' END AS value_sign
FROM (
  SELECT DISTINCT metric_type, period, metric_value
  FROM combined
) t
ORDER BY metric_type, period DESC
LIMIT 100
