WITH avg_warehouse AS (
        SELECT cs.cs_warehouse_sk,
               avg(cs.cs_net_paid_inc_tax) AS avg_net_paid_inc_tax
        FROM catalog_sales cs
        GROUP BY cs.cs_warehouse_sk
    )
SELECT
    cs.cs_order_number,
    cs.cs_net_paid_inc_tax,
    cs.cs_ext_ship_cost,
    hd.hd_income_band_sk,
    w.w_state,
    r.r_reason_desc,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    CASE
        WHEN cs.cs_net_profit > 1000 THEN 'High'
        WHEN cs.cs_net_profit > 0   THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    aw.avg_net_paid_inc_tax,
    RANK() OVER (PARTITION BY w.w_state ORDER BY cs.cs_net_paid_inc_tax DESC) AS state_profit_rank,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY cs.cs_ext_ship_cost DESC) AS income_ship_rownum
FROM catalog_sales cs
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN avg_warehouse aw
    ON aw.cs_warehouse_sk = cs.cs_warehouse_sk
WHERE cs.cs_ext_ship_cost > 1000
  AND cs.cs_net_paid_inc_tax BETWEEN 300 AND 4000
  AND hd.hd_income_band_sk IN (1, 2, 3)
  AND w.w_state = 'CA'
  AND r.r_reason_desc NOT LIKE '%working%'
  AND sr.sr_return_quantity > 0
  AND cs.cs_ship_date_sk BETWEEN 2452000 AND 2453000
ORDER BY state_profit_rank, cs.cs_net_paid_inc_tax DESC
LIMIT 100
