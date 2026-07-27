WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        t.t_shift
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_current_month = 'Y'
      AND d.d_current_day = 'N'
      AND t.t_shift IN ('first', 'second')
      AND cr.cr_return_amount > 50
      AND cr.cr_return_quantity >= 1
)
SELECT
    fr.d_year,
    fr.d_month_seq,
    fr.t_hour,
    fr.t_shift,
    fr.cr_item_sk,
    fr.cr_return_amount,
    fr.cr_return_tax,
    CASE
        WHEN fr.cr_return_amount > 100 THEN 'High'
        WHEN fr.cr_return_amount > 75 THEN 'Medium'
        ELSE 'Low'
    END AS amount_category,
    COUNT(*) OVER (PARTITION BY fr.d_year, fr.t_shift) AS returns_per_year_shift,
    RANK() OVER (PARTITION BY fr.d_year ORDER BY fr.cr_return_amount DESC) AS amount_rank,
    (SELECT SUM(wr2.wr_return_tax)
     FROM web_returns wr2
     WHERE wr2.wr_returned_date_sk = fr.cr_returned_date_sk
       AND wr2.wr_returned_time_sk = fr.cr_returned_time_sk
       AND wr2.wr_return_tax > 10) AS web_tax_sum
FROM filtered_returns fr
JOIN web_returns wr
    ON wr.wr_returned_date_sk = fr.cr_returned_date_sk
   AND wr.wr_returned_time_sk = fr.cr_returned_time_sk
WHERE wr.wr_return_tax BETWEEN 5 AND 30
  AND wr.wr_reversed_charge < 200
ORDER BY fr.d_year, amount_rank
LIMIT 100
