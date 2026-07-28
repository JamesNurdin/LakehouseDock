WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
)
SELECT
    sm.sm_ship_mode_id,
    hd.hd_buy_potential,
    CONCAT(sm.sm_ship_mode_id, '_', hd.hd_buy_potential) AS mode_buy_label,
    SUM(sr.cs_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.cr_return_amount, 0)) AS total_return_amount,
    SUM(sr.cs_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.cr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT sr.cs_order_number) AS order_count
FROM sales_returns sr
JOIN ship_mode sm
    ON sr.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
    ON sr.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE regexp_like(sm.sm_contract, '\\d')
  AND hd.hd_buy_potential LIKE '5%'
GROUP BY sm.sm_ship_mode_id, hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
