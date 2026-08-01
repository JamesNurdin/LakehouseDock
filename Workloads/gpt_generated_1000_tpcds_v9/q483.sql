WITH base_agg AS (
    SELECT
        cc.cc_division_name,
        hd_bill.hd_buy_potential,
        tsold.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS profit_positive,
        SUM(CASE WHEN cs.cs_net_profit <= 0 THEN cs.cs_net_profit ELSE 0 END) AS profit_negative,
        CASE WHEN hd_bill.hd_buy_potential = 'Unknown' THEN 0 ELSE 1 END AS known_buy_potential_flag,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim tsold
        ON cs.cs_sold_time_sk = tsold.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
    JOIN time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE hd_bill.hd_vehicle_count > 0
      AND hd_bill.hd_income_band_sk IN (13, 15)
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND tsold.t_hour BETWEEN 8 AND 17
      AND cs.cs_ext_ship_cost > 0
    GROUP BY ROLLUP (cc.cc_division_name, hd_bill.hd_buy_potential, tsold.t_hour)
)
SELECT
    division_name,
    buy_potential,
    hour_of_sale,
    total_sales,
    total_profit,
    total_returns,
    distinct_orders,
    known_buy_potential_flag,
    avg_discount,
    total_profit / NULLIF(total_sales, 0) AS profit_margin
FROM (
    SELECT
        cc_division_name AS division_name,
        hd_buy_potential AS buy_potential,
        t_hour AS hour_of_sale,
        total_sales,
        total_profit,
        total_returns,
        distinct_orders,
        known_buy_potential_flag,
        avg_discount
    FROM base_agg
) b
WHERE total_sales > (SELECT AVG(total_sales) FROM base_agg)
ORDER BY profit_margin DESC NULLS LAST
