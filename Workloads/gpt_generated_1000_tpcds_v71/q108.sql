WITH return_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        r.r_reason_desc,
        ca.ca_city,
        ca.ca_state,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_promo_name, '\\d{2}%')
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        r.r_reason_desc,
        ca.ca_city,
        ca.ca_state
)
SELECT DISTINCT
    p_promo_id,
    p_promo_name,
    r_reason_desc,
    CONCAT(ca_city, ', ', ca_state) AS location,
    total_net_loss,
    distinct_returns
FROM return_agg
ORDER BY total_net_loss DESC
LIMIT 100
