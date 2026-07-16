WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_time_sk,
        ss.ss_addr_sk,
        ss.ss_cdemo_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_coupon_amt,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_ticket_number,
        ib.ib_income_band_sk
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN income_band ib
        ON cd.cd_purchase_estimate >= ib.ib_lower_bound
           AND cd.cd_purchase_estimate < ib.ib_upper_bound
    WHERE td.t_hour BETWEEN 12 AND 14
      AND ca.ca_state = 'CA'
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    fs.ib_income_band_sk,
    COUNT(*) AS txn_count,
    SUM(fs.ss_net_profit) AS total_net_profit,
    AVG(fs.ss_net_profit) AS avg_net_profit,
    SUM(fs.ss_ext_discount_amt) / NULLIF(SUM(fs.ss_quantity), 0) AS avg_discount_per_item,
    100.0 * SUM(CASE WHEN fs.ss_coupon_amt > 0 THEN 1 ELSE 0 END) / COUNT(*) AS pct_txn_with_coupon
FROM filtered_sales fs
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
GROUP BY s.s_store_name, s.s_city, s.s_state, fs.ib_income_band_sk
HAVING COUNT(*) >= 100
ORDER BY avg_net_profit DESC
LIMIT 10
