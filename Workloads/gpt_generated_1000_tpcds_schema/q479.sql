WITH
    catalog_agg AS (
        SELECT
            cs.cs_call_center_sk,
            cs.cs_promo_sk,
            cs.cs_ship_cdemo_sk,
            cs.cs_bill_cdemo_sk,
            SUM(cs.cs_net_paid)                AS catalog_net_paid,
            SUM(cs.cs_quantity)                AS total_quantity,
            SUM(cs.cs_list_price * cs.cs_quantity) AS list_price_total
        FROM tpcds.catalog_sales cs
        GROUP BY
            cs.cs_call_center_sk,
            cs.cs_promo_sk,
            cs.cs_ship_cdemo_sk,
            cs.cs_bill_cdemo_sk
    ),
    except_orders AS (
        SELECT cs_order_number FROM tpcds.catalog_sales
        EXCEPT
        SELECT ws_order_number FROM tpcds.web_sales
    ),
    intersect_cc AS (
        SELECT cc_call_center_sk FROM tpcds.call_center
        INTERSECT
        SELECT cs_call_center_sk FROM tpcds.catalog_sales
    )
SELECT
    ca.cs_call_center_sk,
    ca.catalog_net_paid,
    ca.total_quantity,
    cc.cc_name,
    p2.p_promo_name            AS catalog_promo_name,
    ss.ss_store_sk,
    ss.ss_net_paid,
    cd1.cd_education_status,
    p1.p_promo_name            AS store_promo_name,
    ws.ws_net_paid_inc_ship_tax,
    p3.p_promo_name            AS web_promo_name,
    lt.line_total,
    kv.key                     AS metric,
    kv.value                   AS metric_value,
    eo.cs_order_number         AS missing_order_number
FROM catalog_agg ca

-- Join to Call Center (full outer to keep unmatched rows from both sides)
FULL OUTER JOIN tpcds.call_center cc ON ca.cs_call_center_sk = cc.cc_call_center_sk

-- Join to Promotion for the catalog side (first alias)
JOIN tpcds.promotion p2 ON ca.cs_promo_sk = p2.p_promo_sk

-- Join to another Promotion alias (second use of the same rule)
JOIN tpcds.promotion p4 ON ca.cs_promo_sk = p4.p_promo_sk

-- Join to Customer Demographics via ship_cdemo_sk (first CD alias)
JOIN tpcds.customer_demographics cd3 ON ca.cs_ship_cdemo_sk = cd3.cd_demo_sk

-- Join to Customer Demographics via bill_cdemo_sk (second CD alias)
JOIN tpcds.customer_demographics cd4 ON ca.cs_bill_cdemo_sk = cd4.cd_demo_sk

-- Bring in Store Sales and its related dimensions
JOIN tpcds.store_sales ss ON ss.ss_cdemo_sk = cd3.cd_demo_sk
JOIN tpcds.customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
JOIN tpcds.promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk

-- Bring in Web Sales and its related dimensions
JOIN tpcds.web_sales ws ON ws.ws_bill_cdemo_sk = cd4.cd_demo_sk
JOIN tpcds.promotion p3 ON ws.ws_promo_sk = p3.p_promo_sk

-- LATERAL subquery to compute a line total from the store‑sales row
CROSS JOIN LATERAL (
    SELECT ss.ss_quantity * ss.ss_sales_price AS line_total
) lt

-- Expand a map built from store‑sales columns using UNNEST
CROSS JOIN LATERAL (
    SELECT map(
        ARRAY[ 'quantity', 'sales_price' ],
        ARRAY[ ss.ss_quantity, ss.ss_sales_price ]
    ) AS kv_map
) m
CROSS JOIN UNNEST (m.kv_map) AS kv (key, value)

-- Left join the EXCEPT result to flag missing order numbers
LEFT JOIN except_orders eo ON ca.cs_call_center_sk = eo.cs_order_number

WHERE cc.cc_name IS NOT NULL               -- ensure we have a matching call‑center after the FULL OUTER join

GROUP BY
    ca.cs_call_center_sk,
    ca.catalog_net_paid,
    ca.total_quantity,
    cc.cc_name,
    p2.p_promo_name,
    ss.ss_store_sk,
    ss.ss_net_paid,
    cd1.cd_education_status,
    p1.p_promo_name,
    ws.ws_net_paid_inc_ship_tax,
    p3.p_promo_name,
    lt.line_total,
    kv.key,
    kv.value,
    eo.cs_order_number

ORDER BY ca.cs_call_center_sk DESC

LIMIT 100
