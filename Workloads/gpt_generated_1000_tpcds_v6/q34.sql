WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_paid ELSE 0 END) AS profit_net_paid,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count >= 1
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND sr.sr_reversed_charge > 1000
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, p.p_promo_name, cd.cd_gender
    HAVING SUM(ss.ss_net_paid) > 5000
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    p_promo_name,
    cd_gender,
    total_net_paid,
    total_net_profit,
    avg_discount,
    profit_net_paid,
    txn_count,
    CASE WHEN total_net_profit > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC) AS sales_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
