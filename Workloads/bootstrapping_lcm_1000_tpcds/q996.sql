SELECT
    p.p_promo_name,
    p.p_promo_id,
    p.p_discount_active,
    s.s_store_name,
    s.s_state,
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_name AS sold_quarter,
    hd_bill.hd_buy_potential AS billing_buy_potential,
    hd_ship.hd_buy_potential AS shipping_buy_potential,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_days,
    MAX(date_diff('day', d_promo_start.d_date, d_promo_end.d_date)) AS promo_duration_days,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS profit_margin
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    p.p_promo_name,
    p.p_promo_id,
    p.p_discount_active,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_name,
    hd_bill.hd_buy_potential,
    hd_ship.hd_buy_potential
ORDER BY total_net_profit DESC
LIMIT 100
