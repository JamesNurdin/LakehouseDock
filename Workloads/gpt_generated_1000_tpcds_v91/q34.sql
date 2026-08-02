WITH combined AS (
    SELECT td.t_hour AS hour,
           i.i_category AS category,
           COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
           COUNT(DISTINCT sr.sr_returned_date_sk) AS distinct_return_days
    FROM store_returns sr
    RIGHT OUTER JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    WHERE td.t_hour < 12
    GROUP BY td.t_hour, i.i_category
    UNION ALL
    SELECT td.t_hour AS hour,
           i.i_category AS category,
           COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
           COUNT(DISTINCT cr.cr_order_number) AS distinct_return_days
    FROM catalog_returns cr
    RIGHT OUTER JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE td.t_hour >= 12
    GROUP BY td.t_hour, i.i_category
)
SELECT c.hour,
       c.category,
       c.total_return_amount,
       (
           SELECT AVG(c2.total_return_amount)
           FROM combined c2
           WHERE c2.category = c.category
       ) AS avg_category_return,
       (
           SELECT SUM(c3.total_return_amount)
           FROM combined c3
           WHERE c3.hour = c.hour
       ) AS sum_hour_return
FROM combined c
ORDER BY c.total_return_amount DESC
LIMIT 100
