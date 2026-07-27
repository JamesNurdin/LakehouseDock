WITH wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_web_page_sk,
        wr.wr_refunded_customer_sk,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_tax) AS avg_return_tax
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000               -- filter on surrogate date key
      AND wr.wr_return_quantity > 1                                        -- only returns with more than one item
      AND wr.wr_return_amt > 10.00                                         -- return amount threshold
      AND wr.wr_return_tax BETWEEN 5.00 AND 30.00                          -- realistic tax range
      AND wr.wr_fee IS NOT NULL                                            -- fee must be present
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk, wr.wr_web_page_sk, wr.wr_refunded_customer_sk
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT cr.c_customer_sk) AS unique_refunded_customers,
    SUM(wa.total_return_amt) AS sum_return_amt,
    AVG(wa.avg_return_tax) AS overall_avg_tax,
    CASE
        WHEN ib.ib_upper_bound <= 50000 THEN 'Low Income'
        WHEN ib.ib_upper_bound <= 100000 THEN 'Mid Income'
        ELSE 'High Income'
    END AS income_segment
FROM wr_agg wa
JOIN item i
    ON wa.wr_item_sk = i.i_item_sk
JOIN date_dim d
    ON wa.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wa.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer cr
    ON wa.wr_refunded_customer_sk = cr.c_customer_sk
JOIN household_demographics hd
    ON cr.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN date_dim dp   -- page creation date, just to involve the table again
    ON wp.wp_creation_date_sk = dp.d_date_sk
WHERE i.i_current_price > 100.00                     -- filter on item price
  AND ib.ib_lower_bound >= 0                         -- realistic lower bound filter
  AND dp.d_year = 2002                               -- restrict to a specific calendar year for page creation
GROUP BY
    d.d_year,
    i.i_category,
    i.i_brand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN ib.ib_upper_bound <= 50000 THEN 'Low Income'
        WHEN ib.ib_upper_bound <= 100000 THEN 'Mid Income'
        ELSE 'High Income'
    END
HAVING
    SUM(wa.total_return_amt) > 1000                 -- keep only high‑value return groups
    AND COUNT(DISTINCT cr.c_customer_sk) >= 5
ORDER BY sum_return_amt DESC
LIMIT 100
