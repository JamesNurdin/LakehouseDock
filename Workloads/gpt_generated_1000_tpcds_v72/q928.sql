WITH item_reason_agg AS (
    SELECT
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(sr.sr_store_credit) AS avg_store_credit,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    INNER JOIN item i ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT OUTER JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE
        sr.sr_return_amt_inc_tax > 100
        AND sr.sr_store_credit <= 25
        AND i.i_manager_id IN (11, 18, 19)
        AND r.r_reason_desc LIKE '%warranty%'
        AND td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category, r.r_reason_desc
)
SELECT
    ira.i_category,
    ira.r_reason_desc,
    ira.total_return_inc_tax,
    ira.avg_store_credit,
    ira.return_cnt,
    (
        SELECT MAX(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = ira.i_category
    ) AS max_price_in_category
FROM item_reason_agg ira
WHERE ira.return_cnt >= 10
  AND ira.total_return_inc_tax > (
        SELECT AVG(total_return_inc_tax)
        FROM item_reason_agg
    )
ORDER BY ira.total_return_inc_tax DESC
LIMIT 100
