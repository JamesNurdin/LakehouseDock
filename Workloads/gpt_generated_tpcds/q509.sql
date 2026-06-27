WITH sales_enriched AS (
    SELECT
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_net_profit,
        td.t_hour,
        hd.hd_vehicle_count,
        p.p_channel_email
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
)
SELECT
    t_hour,
    hd_vehicle_count,
    p_channel_email,
    COUNT(*) AS transaction_cnt,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_ext_discount_amt) AS total_discount,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_ext_discount_amt) / NULLIF(SUM(ss_ext_sales_price), 0) AS discount_rate,
    AVG(ss_ext_sales_price) AS avg_sales_per_txn
FROM sales_enriched
GROUP BY t_hour, hd_vehicle_count, p_channel_email
ORDER BY t_hour, hd_vehicle_count
