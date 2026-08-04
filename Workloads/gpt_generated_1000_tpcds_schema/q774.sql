WITH filtered_sales AS (
    SELECT
        cp.cp_type AS dim_type,
        w.w_state AS dim_state,
        cc.cc_name AS dim_name,
        SUM(cs.cs_net_paid_inc_ship_tax) AS metric1,
        COUNT(DISTINCT cs.cs_order_number) AS metric2
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        regexp_like(cp.cp_description, '(?i)store')
        AND cp.cp_type LIKE 'monthly%'
        AND substring(w.w_city, 1, 3) = 'New'
        AND cs.cs_order_number NOT IN (
            SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 1000
        )
    GROUP BY CUBE(cp.cp_type, w.w_state, cc.cc_name)
),
inventory_agg AS (
    SELECT
        CAST(NULL AS varchar) AS dim_type,
        w2.w_state AS dim_state,
        CAST(NULL AS varchar) AS dim_name,
        CAST(SUM(inv.inv_quantity_on_hand) AS decimal(15,2)) AS metric1,
        COUNT(*) AS metric2
    FROM (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv
    JOIN warehouse w2 ON inv.inv_warehouse_sk = w2.w_warehouse_sk
    WHERE
        w2.w_suite_number LIKE 'Suite %'
        AND regexp_extract(w2.w_county, '(\\w+) County', 1) = 'Walker'
        AND inv.inv_item_sk NOT IN (
            SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 1000
        )
    GROUP BY CUBE(w2.w_state)
)
SELECT dim_type, dim_state, dim_name, metric1, metric2
FROM filtered_sales
UNION DISTINCT
SELECT dim_type, dim_state, dim_name, metric1, metric2
FROM inventory_agg
ORDER BY metric1 DESC NULLS LAST
LIMIT 100
