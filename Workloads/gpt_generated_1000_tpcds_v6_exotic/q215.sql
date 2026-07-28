WITH agg_returns AS (
    SELECT
        sr_addr_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS sum_return_amt,
        SUM(sr_return_quantity) AS sum_qty,
        MAX(sr_reversed_charge) AS max_rev_charge
    FROM store_returns
    WHERE sr_return_quantity >= 5
      AND sr_return_amt > 10
      AND sr_reversed_charge BETWEEN 10 AND 400
      AND sr_return_tax > 0
      AND sr_fee < 100
      AND sr_net_loss IS NOT NULL
    GROUP BY sr_addr_sk, sr_reason_sk
)
SELECT DISTINCT
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    r.r_reason_desc,
    agg.sum_return_amt,
    agg.sum_qty,
    agg.max_rev_charge,
    CASE
        WHEN agg.max_rev_charge > 200 THEN 'High'
        WHEN agg.max_rev_charge > 100 THEN 'Medium'
        ELSE 'Low'
    END AS rev_charge_category,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY agg.sum_return_amt DESC) AS state_return_rank,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY agg.sum_qty DESC) AS city_qty_rownum
FROM agg_returns agg
JOIN customer_address ca
    ON agg.sr_addr_sk = ca.ca_address_sk
JOIN reason r
    ON agg.sr_reason_sk = r.r_reason_sk
WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
  AND ca.ca_country = 'United States'
  AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
  AND r.r_reason_desc LIKE '%product%'
  AND r.r_reason_desc NOT LIKE '%missing%'
  AND ca.ca_zip LIKE '9%'
ORDER BY state_return_rank, ca.ca_city
LIMIT 100
