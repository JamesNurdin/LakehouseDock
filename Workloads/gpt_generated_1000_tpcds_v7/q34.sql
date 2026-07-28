WITH store_data AS (
    SELECT
        s.s_store_id AS entity_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
      AND d.d_year BETWEEN 1998 AND 2000
      AND NOT EXISTS (
            SELECT 1 FROM inventory inv
            WHERE inv.inv_item_sk = ss.ss_item_sk
              AND inv.inv_quantity_on_hand > 1000
        )
    GROUP BY s.s_store_id, d.d_year
),
catalog_data AS (
    SELECT
        cc.cc_call_center_id AS entity_id,
        d.d_year AS year,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_country = 'United States'
      AND d.d_year BETWEEN 1998 AND 2000
      AND i.i_brand_id IN (
            SELECT DISTINCT i2.i_brand_id
            FROM item i2
            WHERE i2.i_formulation LIKE '%goldenrod%'
        )
    GROUP BY cc.cc_call_center_id, d.d_year
),
combined AS (
    SELECT entity_id, year, total_net_paid_inc_tax, profit_flag FROM store_data
    UNION ALL
    SELECT entity_id, year, total_net_paid_inc_tax, profit_flag FROM catalog_data
)
SELECT entity_id, year, total_net_paid_inc_tax, profit_flag
FROM combined
WHERE NOT EXISTS (
    SELECT 1 FROM store s2
    WHERE s2.s_store_id = combined.entity_id
      AND s2.s_city = 'UNKNOWN'
)
ORDER BY year DESC, total_net_paid_inc_tax DESC
LIMIT 100
