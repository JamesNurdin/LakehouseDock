SELECT source_type,
       identifier,
       period,
       total_amount,
       amount_category,
       overall_avg_ws
FROM (
    SELECT
        'Promotion' AS source_type,
        p.p_promo_name AS identifier,
        t.t_shift AS period,
        SUM(ws.ws_net_paid) AS total_amount,
        CASE WHEN SUM(ws.ws_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT CAST(avg(ws2.ws_net_paid) AS decimal(7,2)) FROM web_sales ws2) AS overall_avg_ws
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE p.p_channel_event = 'N'
    GROUP BY p.p_promo_name, t.t_shift
    UNION
    SELECT
        'Address' AS source_type,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS identifier,
        t.t_shift AS period,
        SUM(sr.sr_return_amt) AS total_amount,
        CASE WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS amount_category,
        (SELECT CAST(avg(ws2.ws_net_paid) AS decimal(7,2)) FROM web_sales ws2) AS overall_avg_ws
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_ship_cost > 100
    GROUP BY ca.ca_city, ca.ca_state, t.t_shift
) AS combined
ORDER BY total_amount DESC
LIMIT 100
