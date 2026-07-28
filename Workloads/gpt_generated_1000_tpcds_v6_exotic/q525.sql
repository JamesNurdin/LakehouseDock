WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_call_center_sk, cs_ship_mode_sk, cs_bill_hdemo_sk
    HAVING SUM(cs_ext_sales_price) > 10000
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    sm.sm_type,
    hd.hd_buy_potential,
    r.r_reason_desc,
    agg.total_sales,
    agg.total_profit,
    agg.total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY agg.total_profit DESC) AS profit_rank,
    SUM(agg.total_sales) OVER (PARTITION BY cc.cc_call_center_id ORDER BY agg.total_sales
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales
FROM cs_agg agg
JOIN call_center cc ON agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd ON agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
  AND hd.hd_buy_potential = '1001-5000'
  AND sm.sm_code = 'AIR'
  AND wr.wr_return_ship_cost > 50
  AND r.r_reason_desc LIKE '%damage%'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    sm.sm_type,
    hd.hd_buy_potential,
    r.r_reason_desc,
    agg.total_sales,
    agg.total_profit,
    agg.total_quantity
HAVING SUM(wr.wr_return_amt) > 2000
ORDER BY agg.total_profit DESC
LIMIT 100
