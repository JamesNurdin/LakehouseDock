WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_sold_time_sk,
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        ca.ca_state,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        sr.sr_return_tax,
        sr.sr_return_quantity,
        r.r_reason_desc,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_ext_list_price,
        ws.ws_web_page_sk,
        wp.wp_url,
        sm.sm_carrier
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_sales_price > 100
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_upper_bound <= 50000
      AND sm.sm_carrier = 'UPS'
      AND sr.sr_return_tax BETWEEN 2 AND 10
),
url_exploded AS (
    SELECT
        f.*, 
        part.url_part
    FROM filtered_sales f
    CROSS JOIN UNNEST(split(f.wp_url, '/')) AS part(url_part)
),
final_ranked AS (
    SELECT
        ue.ss_ticket_number,
        ue.ca_state,
        (ue.ss_net_profit + ue.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ue.ca_state ORDER BY (ue.ss_net_profit + ue.ws_net_profit) DESC) AS profit_rank,
        CASE WHEN ue.sr_return_tax IS NULL THEN 'No Return' ELSE 'Returned' END AS return_status,
        ue.url_part
    FROM url_exploded ue
    WHERE ue.ss_ticket_number NOT IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 5
    )
)
SELECT
    fr.ss_ticket_number,
    fr.ca_state,
    fr.total_profit,
    fr.profit_rank,
    fr.return_status,
    fr.url_part
FROM final_ranked fr
ORDER BY fr.profit_rank ASC, fr.ss_ticket_number ASC
