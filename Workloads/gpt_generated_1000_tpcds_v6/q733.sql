WITH filtered AS (
    SELECT
        i.i_brand_id,
        i.i_class,
        i.i_category,
        sr.sr_return_amt,
        sr.sr_store_credit,
        sr.sr_return_ship_cost,
        sr.sr_reversed_charge,
        sr.sr_return_quantity
    FROM tpcds.item i
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_start_date <= DATE '2000-12-31'
      AND i.i_brand_id IN (5003002, 2004001)
      AND i.i_class = 'furniture'
      AND sr.sr_return_amt > 100
      AND sr.sr_store_credit < 500
      AND sr.sr_return_ship_cost BETWEEN 10 AND 200
      AND sr.sr_reversed_charge > 50
)
SELECT
    f.i_brand_id,
    f.i_class,
    COUNT(*) AS total_returns,
    SUM(f.sr_return_amt) AS total_return_amount,
    AVG(f.sr_store_credit) AS avg_store_credit,
    MIN(f.sr_return_ship_cost) AS min_ship_cost,
    MAX(f.sr_return_ship_cost) AS max_ship_cost,
    (SELECT AVG(sr2.sr_return_amt) FROM tpcds.store_returns sr2) AS overall_avg_return_amt
FROM filtered f
GROUP BY f.i_brand_id, f.i_class
HAVING SUM(f.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 10
