WITH sales_agg AS (
    SELECT
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        cc.cc_company AS company,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_company IN (1, 3, 5)
      AND cp.cp_department = 'Sports'
      AND cs.cs_sold_date_sk BETWEEN 2451060 AND 2451088
      AND i.i_brand = 'Brand#12'
    GROUP BY cs.cs_bill_hdemo_sk, cc.cc_company, cs.cs_item_sk
),
hd_demo AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_dep_count,
        hd_vehicle_count
    FROM household_demographics
    WHERE hd_income_band_sk IN (3, 4, 9)
      AND hd_dep_count >= 1
),
inventory_agg AS (
    SELECT
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS inv_records
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk IN (10, 13, 17)
      AND inv.inv_date_sk = 2451067
    GROUP BY i.i_item_sk
)
SELECT *
FROM (
    SELECT
        sa.hd_demo_sk,
        hd.hd_income_band_sk,
        sa.company,
        sa.total_net_paid,
        hd.hd_dep_count
    FROM sales_agg sa
    JOIN hd_demo hd
        ON sa.hd_demo_sk = hd.hd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM inventory inv_chk
        WHERE inv_chk.inv_item_sk = sa.item_sk
          AND inv_chk.inv_quantity_on_hand > 0
    )
    UNION ALL
    SELECT DISTINCT
        ia.i_item_sk AS hd_demo_sk,
        NULL AS hd_income_band_sk,
        NULL AS company,
        ia.total_qty AS total_net_paid,
        NULL AS hd_dep_count
    FROM inventory_agg ia
    WHERE ia.total_qty > 1000
) combined
ORDER BY total_net_paid DESC
LIMIT 100
