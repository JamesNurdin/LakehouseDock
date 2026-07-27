WITH cs_base AS (
    SELECT
        cs.cs_sold_time_sk AS time_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cc.cc_name,
        cc.cc_street_number,
        cc.cc_hours,
        wh.w_warehouse_name,
        hd.hd_income_band_sk,
        td.t_hour,
        td.t_minute
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_street_number = '415'
      AND cc.cc_hours = '8AM-4PM'
      AND td.t_minute IN (15, 7)
      AND cs.cs_quantity >= 5
)
SELECT
    csb.cc_name,
    csb.cc_street_number,
    csb.cc_hours,
    st.s_store_name,
    csb.t_hour,
    CASE WHEN csb.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    SUM(csb.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT csb.cs_order_number) AS order_cnt,
    AVG(csb.cs_net_profit) AS avg_profit,
    MIN(csb.cs_ext_sales_price) AS min_sales,
    MAX(csb.cs_ext_sales_price) AS max_sales
FROM cs_base csb
JOIN store_returns sr
    ON sr.sr_return_time_sk = csb.time_sk
JOIN store st
    ON sr.sr_store_sk = st.s_store_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = csb.cs_warehouse_sk
WHERE st.s_state = 'CA'
  AND inv.inv_quantity_on_hand > 100
  AND sr.sr_return_amt > 50
GROUP BY
    csb.cc_name,
    csb.cc_street_number,
    csb.cc_hours,
    st.s_store_name,
    csb.t_hour,
    CASE WHEN csb.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
ORDER BY total_sales DESC
LIMIT 100
