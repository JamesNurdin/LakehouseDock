WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_txn_count,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_purpose = 'Unknown'
      AND p.p_channel_catalog = 'N'
      AND hd.hd_buy_potential IN ('1001-5000', '0-500')
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
    GROUP BY ss.ss_ticket_number, ss.ss_store_sk, s.s_store_name, s.s_state
),
returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_fee) AS total_return_fee,
        COUNT(*) AS return_txn_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_fee > 10
    GROUP BY sr.sr_ticket_number
)
SELECT
    sa.ss_ticket_number,
    sa.s_store_name,
    sa.s_state,
    sa.total_net_profit,
    sa.total_sales_amount,
    ra.total_return_amount,
    ra.total_return_fee,
    CASE
        WHEN ra.total_return_fee IS NULL THEN 0
        ELSE ra.total_return_fee
    END AS return_fee_coalesced,
    RANK() OVER (PARTITION BY sa.s_state ORDER BY sa.total_net_profit DESC) AS profit_rank_state,
    (SELECT AVG(ib_lower_bound) FROM income_band) AS avg_income_lower_bound
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.ss_ticket_number = ra.sr_ticket_number
ORDER BY profit_rank_state, sa.total_net_profit DESC
LIMIT 100
