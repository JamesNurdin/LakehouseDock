SELECT
    s.s_store_name,
    i.i_category,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM store_returns sr
JOIN (
    SELECT i_item_sk, i_category
    FROM item
    WHERE i_brand_id = 3003001
) i ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
WHERE t.t_hour = 16
GROUP BY s.s_store_name, i.i_category
HAVING COUNT(*) > 11
