WITH dim AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        p.p_promo_id,
        p.p_channel_email,
        p.p_channel_event,
        ca.ca_state,
        ca.ca_country,
        ca.ca_city,
        hd.hd_vehicle_count,
        hd.hd_dep_count
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
)
SELECT
    d.ss_ticket_number,
    d.ca_state,
    d.ca_country,
    d.p_promo_id,
    d.ss_net_profit,
    COALESCE(r.cr_return_amount, 0) AS total_return_amount,
    CASE WHEN COALESCE(r.cr_return_amount, 0) > 0 THEN 'Returned' ELSE 'NoReturn' END AS return_flag,
    ROW_NUMBER() OVER (PARTITION BY d.ca_state ORDER BY d.ss_net_profit DESC) AS profit_rank_state,
    SUM(d.ss_net_profit) OVER (
        PARTITION BY d.ca_state
        ORDER BY d.ss_ticket_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_state
FROM dim d
LEFT JOIN catalog_returns r
    ON r.cr_returning_hdemo_sk = d.ss_hdemo_sk
   AND r.cr_returning_addr_sk = d.ss_addr_sk
LEFT JOIN ship_mode sm
    ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.ca_country = 'United States'
  AND d.p_channel_event = 'N'
  AND d.hd_vehicle_count >= 1
  AND sm.sm_carrier = 'UPS'
  AND d.ss_sold_date_sk BETWEEN 2451910 AND 2451915
ORDER BY d.ca_state, profit_rank_state
LIMIT 100
