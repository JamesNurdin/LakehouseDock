WITH sales_q4 AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND d.d_qoy = 4
)
SELECT
    cc.cc_name,
    hd.hd_buy_potential,
    COUNT(DISTINCT s.cs_order_number) AS orders,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(s.cs_net_profit) AS total_net_profit,
    SUM(s.cs_ext_discount_amt) AS total_discount,
    ROUND(SUM(s.cs_net_profit) / NULLIF(SUM(s.cs_net_paid), 0), 4) AS profit_margin,
    RANK() OVER (ORDER BY SUM(s.cs_net_profit) DESC) AS profit_rank
FROM sales_q4 s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE cc.cc_gmt_offset = -5.00
  AND hd.hd_buy_potential = 'High'
  AND cc.cc_city IN ('Greenwood', 'Glendale')
GROUP BY cc.cc_name, hd.hd_buy_potential
HAVING SUM(s.cs_net_paid) > 10000
ORDER BY profit_margin DESC, total_net_paid DESC
LIMIT 10
