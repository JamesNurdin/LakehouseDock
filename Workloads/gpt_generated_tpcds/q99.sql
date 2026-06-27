SELECT
    ca.ca_state,
    hd.hd_vehicle_count,
    sum(sr.sr_net_loss) AS total_net_loss,
    avg(sr.sr_return_amt) AS avg_return_amount,
    count(*) AS total_returns,
    avg(sr.sr_net_loss / nullif(sr.sr_return_quantity, 0)) AS avg_loss_per_item
FROM store_returns sr
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_return_quantity > 0
GROUP BY ca.ca_state, hd.hd_vehicle_count
ORDER BY total_net_loss DESC
LIMIT 100
