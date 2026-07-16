WITH store_monthly AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_total_discount,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2020
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy
),
catalog_monthly AS (
    SELECT
        cs.cs_promo_sk,
        d.d_year,
        d.d_moy,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY cs.cs_promo_sk, d.d_year, d.d_moy
),
inventory_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_year, d.d_moy
)
SELECT
    sm.s_store_id,
    sm.s_store_name,
    sm.d_year,
    sm.d_moy,
    sm.store_net_profit,
    cm.catalog_net_profit,
    im.avg_inventory_qty,
    sm.store_net_profit / NULLIF(im.avg_inventory_qty, 0) AS profit_per_inventory,
    RANK() OVER (PARTITION BY sm.d_year, sm.d_moy ORDER BY sm.store_net_profit DESC) AS store_monthly_rank
FROM store_monthly sm
LEFT JOIN catalog_monthly cm
    ON sm.d_year = cm.d_year AND sm.d_moy = cm.d_moy
LEFT JOIN inventory_monthly im
    ON sm.d_year = im.d_year AND sm.d_moy = im.d_moy
WHERE sm.store_net_profit > 0
ORDER BY sm.d_year, sm.d_moy, store_monthly_rank
LIMIT 100
