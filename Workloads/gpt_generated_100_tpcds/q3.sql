SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    r.r_reason_desc,
    i.i_category,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(i.i_current_price) AS avg_item_price
FROM store_returns sr
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE sr.sr_return_quantity > 1
  AND cd.cd_credit_rating = 'A'
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    r.r_reason_desc,
    i.i_category
ORDER BY total_net_loss DESC
LIMIT 100
