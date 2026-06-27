SELECT
    i.i_category,
    cd.cd_gender,
    r.r_reason_desc,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_net_loss) AS total_net_loss,
    ROUND(100.0 * SUM(sr.sr_net_loss) / SUM(SUM(sr.sr_net_loss)) OVER (PARTITION BY i.i_category), 2) AS pct_of_category_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_quantity > 0
GROUP BY i.i_category, cd.cd_gender, r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
