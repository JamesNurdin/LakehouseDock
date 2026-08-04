/*
Goal: Analyze net revenue and quantity by call center, item brand, and shipping mode, covering all TPC‑DS dimensions. The query demonstrates deep joins across all eleven selected tables, re‑uses the ITEM table under two aliases (once for the sales fact and once for the promotion‑linked item), includes a FULL OUTER JOIN between CALL_CENTER and the pre‑aggregated sales data, and expands a derived array of quantities with UNNEST. The sales fact is first aggregated in a CTE before being joined to the rest of the model.
*/
WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_call_center_sk,
        cs_promo_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        SUM(cs_net_paid)      AS total_net_paid,
        SUM(cs_quantity)      AS total_quantity
    FROM catalog_sales
    GROUP BY
        cs_item_sk,
        cs_call_center_sk,
        cs_promo_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk
),
qty_expanded AS (
    SELECT
        cs_item_sk,
        cs_call_center_sk,
        cs_promo_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        total_net_paid,
        qty
    FROM sales_agg
    CROSS JOIN UNNEST(ARRAY[total_quantity, total_quantity * 2]) AS t (qty)
)
SELECT
    cc.cc_name                     AS call_center_name,
    i1.i_brand                     AS item_brand,
    sm.sm_type                     AS ship_mode_type,
    SUM(qe.total_net_paid)         AS sum_net_paid,
    SUM(qe.qty)                    AS sum_quantity,
    COUNT(DISTINCT qe.cs_item_sk)  AS distinct_items
FROM qty_expanded qe
FULL OUTER JOIN call_center cc
    ON cc.cc_call_center_sk = qe.cs_call_center_sk
INNER JOIN item i1
    ON i1.i_item_sk = qe.cs_item_sk
INNER JOIN promotion p
    ON p.p_promo_sk = qe.cs_promo_sk
INNER JOIN item i2               -- second alias of ITEM, joined via promotion
    ON i2.i_item_sk = p.p_item_sk
INNER JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = qe.cs_catalog_page_sk
INNER JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = qe.cs_ship_mode_sk
INNER JOIN warehouse w
    ON w.w_warehouse_sk = qe.cs_warehouse_sk
INNER JOIN household_demographics hd
    ON hd.hd_demo_sk = qe.cs_bill_hdemo_sk
INNER JOIN customer_address ca
    ON ca.ca_address_sk = qe.cs_bill_addr_sk
INNER JOIN web_sales ws
    ON ws.ws_item_sk = i1.i_item_sk
INNER JOIN web_site ws_site
    ON ws_site.web_site_sk = ws.ws_web_site_sk
GROUP BY
    cc.cc_name,
    i1.i_brand,
    sm.sm_type
ORDER BY
    sum_net_paid DESC
