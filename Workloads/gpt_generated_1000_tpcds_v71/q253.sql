WITH sr_filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 0
)
SELECT
    d.d_year,
    cd.cd_credit_rating,
    concat(cd.cd_gender, '_', cd.cd_credit_rating) AS gender_credit,
    regexp_extract(d.d_holiday, '(\\w+) Day', 1) AS holiday_name,
    sum(sr.sr_return_amt) AS total_return_amt,
    sum(sr.sr_net_loss) AS total_net_loss,
    avg(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
    count(*) AS return_cnt
FROM sr_filtered sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv
  ON d.d_date_sk = inv.inv_date_sk
WHERE regexp_like(cd.cd_credit_rating, 'Risk$')
  AND d.d_holiday LIKE '%Day%'
  AND substring(d.d_day_name, 1, 3) = 'Sat'
GROUP BY d.d_year,
         cd.cd_credit_rating,
         concat(cd.cd_gender, '_', cd.cd_credit_rating),
         regexp_extract(d.d_holiday, '(\\w+) Day', 1)
ORDER BY total_return_amt DESC
LIMIT 100
