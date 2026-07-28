SELECT month_seq, source, total_return_amt, return_cnt
FROM (
    SELECT dd.d_month_seq AS month_seq,
           'manufact_esecallyable' AS source,
           SUM(wr.wr_return_amt) AS total_return_amt,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_manufact = 'esecallyable'
      AND dd.d_current_month = 'Y'
    GROUP BY dd.d_month_seq

    UNION ALL

    SELECT dd.d_month_seq AS month_seq,
           'class_fragrances' AS source,
           SUM(wr.wr_return_amt) AS total_return_amt,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_class = 'fragrances'
      AND dd.d_current_month = 'N'
    GROUP BY dd.d_month_seq
) AS combined
ORDER BY month_seq, total_return_amt DESC
LIMIT 100
