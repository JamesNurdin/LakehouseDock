WITH bill_sales AS (
    SELECT
        'CallCenter' AS entity_type,
        cc.cc_name AS name,
        hd.hd_buy_potential AS attribute,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential IN ('>10000', '1001-5000')
      AND cc.cc_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM warehouse w2
          WHERE w2.w_state = cc.cc_state
            AND w2.w_warehouse_sq_ft > 100000
      )
    GROUP BY cc.cc_name, hd.hd_buy_potential
),
ship_sales AS (
    SELECT
        'Warehouse' AS entity_type,
        w.w_warehouse_name AS name,
        CAST(hd.hd_dep_count AS varchar) AS attribute,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 3
      AND w.w_city = 'Los Angeles'
      AND w.w_state IN (
          SELECT ca.ca_state
          FROM customer_address ca
          WHERE ca.ca_gmt_offset = -5.00
      )
    GROUP BY w.w_warehouse_name, hd.hd_dep_count
)
SELECT entity_type, name, attribute, total_sales
FROM bill_sales
UNION ALL
SELECT entity_type, name, attribute, total_sales
FROM ship_sales
ORDER BY total_sales DESC
LIMIT 100
