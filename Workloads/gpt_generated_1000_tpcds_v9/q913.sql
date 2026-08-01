WITH store_filter AS (
    SELECT s_store_sk, s_state, s_market_id, s_manager, s_tax_percentage, s_rec_end_date
    FROM store
    WHERE s_state IN ('CA', 'TX', 'NY')
      AND s_market_id IN (1, 5, 7)
      AND s_rec_end_date >= DATE '2000-01-01'
      AND s_rec_end_date <= DATE '2002-12-31'
      AND s_manager = 'Raymond Jacobs'
      AND s_tax_percentage > 0.05
),
joined_data AS (
    SELECT
        sf.s_state,
        sf.s_market_id,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_refunded_cash,
        sr.sr_return_quantity,
        CASE WHEN sr.sr_return_amt > 500 THEN sr.sr_return_amt ELSE 0 END AS high_value_amt
    FROM store_returns sr
    JOIN store_filter sf
        ON sr.sr_store_sk = sf.s_store_sk
    WHERE sr.sr_return_quantity BETWEEN 1 AND 10
      AND sr.sr_return_amt BETWEEN 10 AND 1500
      AND sr.sr_return_tax >= 0.5
      AND sr.sr_refunded_cash > 0
      AND EXISTS (
          SELECT 1
          FROM store s
          WHERE s.s_store_sk = sr.sr_store_sk
            AND s.s_manager = 'Edwin Adams'
            AND s.s_country = 'United States'
      )
),
aggregated AS (
    SELECT
        s_state,
        s_market_id,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MIN(sr_refunded_cash) AS min_refunded_cash,
        MAX(sr_refunded_cash) AS max_refunded_cash,
        SUM(high_value_amt) AS total_high_value_amt
    FROM joined_data
    GROUP BY ROLLUP (s_state, s_market_id)
    HAVING SUM(sr_return_amt) > 100
)
SELECT
    s_state,
    s_market_id,
    total_return_amt,
    avg_return_tax,
    return_cnt,
    min_refunded_cash,
    max_refunded_cash,
    total_high_value_amt,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_return_amt DESC) AS state_rank
FROM aggregated
ORDER BY s_state, s_market_id
LIMIT 100
