WITH joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        i.i_brand,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND hd.hd_vehicle_count >= 1
      AND c.c_first_name IN ('Betty', 'Margaret')
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_buy_potential,
    i_brand,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count,
    MAX(sr_return_amt_inc_tax) AS max_return_amount_inc_tax
FROM joined_data
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_buy_potential,
    i_brand
ORDER BY total_return_amount DESC
LIMIT 50
