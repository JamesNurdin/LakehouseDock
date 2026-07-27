WITH warehouse_profit AS (
    SELECT
        cs_warehouse_sk,
        AVG(cs_net_profit) AS avg_warehouse_profit
    FROM catalog_sales
    GROUP BY cs_warehouse_sk
)
SELECT
    cp.cp_catalog_page_number,
    cp.cp_type,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_net_profit,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    CASE
        WHEN cs.cs_net_profit > wp.avg_warehouse_profit THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    COALESCE(p.p_discount_active, 'N') AS promo_discount_active
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN warehouse_profit wp ON cs.cs_warehouse_sk = wp.cs_warehouse_sk
WHERE cp.cp_type = 'monthly'
  AND cs.cs_quantity > 5
  AND cd.cd_credit_rating = 'Good'
  AND ib.ib_lower_bound >= 90000
  AND w.w_state = 'CA'
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
ORDER BY cs.cs_net_profit DESC
LIMIT 100
