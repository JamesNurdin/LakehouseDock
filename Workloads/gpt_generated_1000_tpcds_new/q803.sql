WITH filtered_sales AS (
    SELECT *
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2459999
      AND cs_list_price > (SELECT avg(cs_list_price) FROM catalog_sales)
)
SELECT
    cs.cs_order_number,
    cc.cc_name,
    sm.sm_type,
    c1.c_customer_id,
    c2.c_customer_id AS ship_customer_id,
    hd1.hd_buy_potential,
    ib1.ib_lower_bound,
    CASE
        WHEN cs.cs_net_profit > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_indicator,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    qty_lateral.total_qty
FROM filtered_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c1
  ON cs.cs_bill_customer_sk = c1.c_customer_sk
JOIN customer c2
  ON cs.cs_ship_customer_sk = c2.c_customer_sk
JOIN household_demographics hd1
  ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
JOIN household_demographics hd2
  ON cs.cs_ship_hdemo_sk = hd2.hd_demo_sk
JOIN income_band ib1
  ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
JOIN income_band ib2
  ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
FULL OUTER JOIN store_returns sr
  ON sr.sr_customer_sk = c1.c_customer_sk
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_quantity) AS total_qty
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = c1.c_customer_sk
) AS qty_lateral
WHERE c1.c_preferred_cust_flag = 'Y'
GROUP BY
    cs.cs_order_number,
    cc.cc_name,
    sm.sm_type,
    c1.c_customer_id,
    c2.c_customer_id,
    hd1.hd_buy_potential,
    ib1.ib_lower_bound,
    CASE
        WHEN cs.cs_net_profit > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END,
    qty_lateral.total_qty
ORDER BY total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
