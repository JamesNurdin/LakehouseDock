-- Goal: Summarize net profit, sales and discount performance by call center, sold year and store state, counting distinct billed customers and promotions, and include the overall net profit as a scalar sub‑query.
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_sold.d_year AS sold_year,
    st.s_state,
    COUNT(DISTINCT ca_bill.ca_address_sk) AS distinct_bill_customers,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COUNT(p.p_promo_sk) AS promotion_count,
    (SELECT SUM(cs2.cs_net_profit) FROM catalog_sales cs2) AS grand_total_net_profit
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 1999 AND 2000
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    d_sold.d_year,
    st.s_state
ORDER BY
    total_net_profit DESC,
    sold_year
LIMIT 100
