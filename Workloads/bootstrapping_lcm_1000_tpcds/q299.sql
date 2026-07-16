SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    sd.d_year AS sold_year,
    sd.d_month_seq AS sold_month,
    shd.d_year AS ship_year,
    shd.d_month_seq AS ship_month,
    AVG(date_diff('day', sd.d_date, shd.d_date)) AS avg_days_to_ship,
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_channel_email,
    MIN(psd.d_date) AS promo_start_date,
    MAX(ped.d_date) AS promo_end_date,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_tax) AS total_tax,
    MAX(cs.cs_coupon_amt) AS max_coupon_amt
FROM catalog_sales cs
JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
JOIN date_dim shd ON cs.cs_ship_date_sk = shd.d_date_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim psd ON p.p_start_date_sk = psd.d_date_sk
JOIN date_dim ped ON p.p_end_date_sk = ped.d_date_sk
JOIN store s ON s.s_closed_date_sk = shd.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    sd.d_year,
    sd.d_month_seq,
    shd.d_year,
    shd.d_month_seq,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_gender,
    cd_ship.cd_marital_status,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_channel_email
HAVING
    SUM(cs.cs_net_paid) > 1000
ORDER BY
    total_net_paid DESC
LIMIT 100
