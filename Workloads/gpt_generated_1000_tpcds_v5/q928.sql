WITH sales_agg AS (
    SELECT
        d.d_year                                    AS year,
        cc.cc_name                                  AS call_center_name,
        'Profit'                                    AS metric_type,
        SUM(cs.cs_net_profit)                      AS metric_value,
        CASE WHEN SUM(cs.cs_net_profit) > 50000
             THEN 'High'
             ELSE 'Low'
        END                                        AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cc.cc_name
),
inventory_agg AS (
    SELECT
        d.d_year                                    AS year,
        cc.cc_name                                  AS call_center_name,
        'Inventory'                                 AS metric_type,
        SUM(inv.inv_quantity_on_hand)              AS metric_value,
        CAST(NULL AS varchar)                      AS profit_category
    FROM inventory inv
    JOIN date_dim d
      ON inv.inv_date_sk = d.d_date_sk
    JOIN call_center cc
      ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, cc.cc_name
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM inventory_agg
ORDER BY year, call_center_name, metric_type
LIMIT 100
