WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_time_sk,
        SUM(ss_net_paid) AS total_store_net_paid,
        COUNT(*) AS store_txn_cnt
    FROM store_sales
    WHERE ss_quantity > 2
        AND ss_net_paid > 0
    GROUP BY ss_item_sk, ss_sold_time_sk
),
item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        p.p_promo_sk,
        p.p_promo_name
    FROM item i
    FULL OUTER JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
)
SELECT
    ip.i_item_id,
    ip.i_brand,
    ip.i_category,
    ip.p_promo_name,
    t.t_hour,
    cs.cs_quantity,
    cs.cs_net_paid,
    sm.sm_type,
    hd.hd_income_band_sk,
    ss_agg.total_store_net_paid,
    ss_agg.store_txn_cnt,
    CASE
        WHEN cs.cs_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS cs_profit_flag,
    CASE
        WHEN cr.cr_return_amount > 2000 THEN 'High'
        ELSE 'Low'
    END AS return_severity,
    RANK() OVER (PARTITION BY ip.i_category ORDER BY cs.cs_net_profit DESC) AS category_profit_rank,
    (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = ip.i_item_sk) AS max_item_net_paid,
    (SELECT SUM(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = ip.i_item_sk) AS total_return_amount,
    CASE
        WHEN EXISTS (SELECT 1 FROM catalog_returns cr3 WHERE cr3.cr_item_sk = ip.i_item_sk AND cr3.cr_return_amount > 1500) THEN 1
        ELSE 0
    END AS has_large_return_flag
FROM ss_agg
JOIN item_promo ip
    ON ss_agg.ss_item_sk = ip.i_item_sk
JOIN time_dim t
    ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = ip.i_item_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = ip.i_item_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
    AND cr.cr_order_number = cs.cs_order_number
WHERE ip.i_brand = 'BrandX'
    AND ip.i_category = 'Electronics'
    AND t.t_hour BETWEEN 8 AND 18
    AND cs.cs_quantity > 5
    AND cs.cs_net_paid > 200
    AND cr.cr_return_amount > 1000
    AND sm.sm_type = 'AIR'
ORDER BY category_profit_rank ASC, cs.cs_net_profit DESC
LIMIT 100
