WITH store_returns_filtered AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_return_ship_cost
    FROM store_returns sr
    WHERE sr.sr_return_amt > 100
      AND sr.sr_reversed_charge < 500
      AND sr.sr_store_credit >= 5
      AND sr.sr_return_ship_cost BETWEEN 10 AND 400
),
store_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt)          AS total_return_amt,
        SUM(sr.sr_net_loss)            AS total_net_loss,
        COUNT(*)                       AS return_count
    FROM store_returns_filtered sr
    GROUP BY sr.sr_store_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_county,
    agg.total_return_amt,
    agg.total_net_loss,
    agg.return_count,
    RANK() OVER (PARTITION BY s.s_state ORDER BY agg.total_net_loss DESC) AS state_net_loss_rank,
    CASE
        WHEN agg.total_return_amt > (
            SELECT AVG(t.total_return_amt)
            FROM (
                SELECT SUM(sr_return_amt) AS total_return_amt
                FROM store_returns_filtered
                GROUP BY sr_store_sk
            ) t
        ) THEN 'Above Avg Return'
        ELSE 'Below Avg Return'
    END AS return_category
FROM store_agg agg
JOIN store s ON agg.sr_store_sk = s.s_store_sk
WHERE s.s_country = 'United States'
  AND s.s_state IN ('TX', 'CA', 'NY')
  AND s.s_number_employees > 50
  AND s.s_market_id IN (
        SELECT DISTINCT s2.s_market_id
        FROM store s2
        WHERE s2.s_market_desc LIKE '%Retail%'
    )
ORDER BY agg.total_net_loss DESC
LIMIT 100
