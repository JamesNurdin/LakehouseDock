/* goal: Identify top promotions per store in California, adjusting profit by returns, and rank them by adjusted profit while showing cumulative profit. */
WITH promo_union AS (
    SELECT DISTINCT p.p_promo_sk, p.p_promo_name
    FROM promotion p
    WHERE p.p_channel_tv = 'Y'
    UNION
    SELECT DISTINCT p.p_promo_sk, p.p_promo_name
    FROM promotion p
    WHERE p.p_channel_email = 'Y'
),

sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_state = 'CA'
      AND ib.ib_upper_bound >= 50000
      AND ss.ss_ext_discount_amt > 0
      AND p.p_discount_active = 'Y'
      AND (p.p_channel_tv = 'Y' OR p.p_channel_email = 'Y')
    GROUP BY ss.ss_store_sk, ss.ss_promo_sk
),

returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_hdemo_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 30000
      AND sr.sr_return_quantity > 0
      AND sr.sr_store_credit > 0
    GROUP BY sr.sr_store_sk, sr.sr_hdemo_sk
),

joined AS (
    SELECT
        s.ss_store_sk,
        s.ss_promo_sk,
        s.total_net_paid,
        s.total_net_profit,
        s.distinct_customers,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS adjusted_profit
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.ss_store_sk = r.sr_store_sk
       AND s.ss_promo_sk = r.sr_hdemo_sk
)
SELECT
    j.ss_store_sk,
    pu.p_promo_name,
    j.total_net_paid,
    j.total_return_amt,
    j.adjusted_profit,
    j.distinct_customers,
    RANK() OVER (PARTITION BY j.ss_store_sk ORDER BY j.adjusted_profit DESC) AS profit_rank,
    SUM(j.adjusted_profit) OVER (PARTITION BY j.ss_store_sk ORDER BY j.adjusted_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM joined j
JOIN promo_union pu
    ON j.ss_promo_sk = pu.p_promo_sk
WHERE j.adjusted_profit > (
        SELECT AVG(adjusted_profit)
        FROM joined
        WHERE ss_store_sk = j.ss_store_sk
      )
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = j.ss_store_sk
          AND ss2.ss_promo_sk = j.ss_promo_sk
          AND ss2.ss_quantity > 5
      )
ORDER BY j.ss_store_sk, profit_rank
LIMIT 100
