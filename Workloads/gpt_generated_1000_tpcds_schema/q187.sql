WITH agg_returns AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        sr_cdemo_sk,
        sr_reason_sk,
        SUM(sr_return_amt)          AS total_return_amt,
        AVG(sr_return_quantity)     AS avg_return_qty,
        COUNT(*)                    AS return_cnt,
        SUM(sr_net_loss)            AS total_net_loss
    FROM store_returns
    WHERE sr_return_quantity > 1
    GROUP BY sr_item_sk, sr_returned_date_sk, sr_cdemo_sk, sr_reason_sk
)
SELECT
    d.d_date                     AS return_date,
    i.i_item_id                  AS item_id,
    i.i_product_name             AS product_name,
    i.i_current_price            AS current_price,
    cd.cd_gender                 AS customer_gender,
    cd.cd_credit_rating          AS credit_rating,
    r.r_reason_desc              AS return_reason,
    ar.total_return_amt,
    ar.avg_return_qty,
    ar.return_cnt,
    CASE WHEN ar.total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM agg_returns ar
JOIN item i
  ON ar.sr_item_sk = i.i_item_sk
JOIN date_dim d
  ON ar.sr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON ar.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r
  ON ar.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND i.i_current_price > 50
  AND cd.cd_credit_rating = 'Good'
  AND r.r_reason_id = 'AAAAAAAALAAAAAAA'
  AND d.d_current_year = 'Y'
ORDER BY ar.total_return_amt DESC
LIMIT 100
