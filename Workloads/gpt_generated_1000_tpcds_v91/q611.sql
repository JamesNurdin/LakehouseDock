WITH union_set AS (
    SELECT DISTINCT cc.cc_call_center_sk, cc.cc_name, cs.cs_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA' AND cs.cs_ext_tax > 150
    UNION
    SELECT DISTINCT cc.cc_call_center_sk, cc.cc_name, cs.cs_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'TX' AND cs.cs_wholesale_cost < 30
),
intersect_set AS (
    SELECT cc.cc_call_center_sk, cc.cc_name, cs.cs_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_ext_tax BETWEEN 100 AND 300
    INTERSECT
    SELECT cc.cc_call_center_sk, cc.cc_name, cs.cs_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 5000
)
SELECT DISTINCT merged.cc_call_center_sk, merged.cc_name, merged.cs_net_paid
FROM (
    SELECT union_set.cc_call_center_sk, union_set.cc_name, union_set.cs_net_paid
    FROM union_set
    INTERSECT
    SELECT intersect_set.cc_call_center_sk, intersect_set.cc_name, intersect_set.cs_net_paid
    FROM intersect_set
) AS merged
ORDER BY merged.cc_name
