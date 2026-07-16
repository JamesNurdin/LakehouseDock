SELECT sub.i_brand,
       SUM(sr.sr_return_amt) AS total_return_amount,
       COUNT(*) AS return_count
FROM store_returns sr
INNER JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
INNER JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
INNER JOIN (
    SELECT i_item_sk, i_brand
    FROM item
    WHERE i_brand = 'edu packbrand #4                                  '
) sub ON sr.sr_item_sk = sub.i_item_sk
WHERE td.t_hour = 8
GROUP BY sub.i_brand
HAVING SUM(sr.sr_return_amt) > 28.49
