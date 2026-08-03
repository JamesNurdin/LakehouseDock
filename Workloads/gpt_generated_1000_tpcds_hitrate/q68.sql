WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ws.web_site_id,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS ticket_net_paid,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
        CASE WHEN SUM(ss.ss_quantity) > 5 THEN 'Large' ELSE 'Small' END AS ticket_size
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_income_band_sk > 5
      AND ca.ca_state = 'CA'
      AND ws.web_city = 'Spring Hill'
      AND cs.cs_quantity > 2
    GROUP BY ss.ss_ticket_number, ws.web_site_id, cd.cd_gender
)
SELECT
    b.web_site_id,
    b.cd_gender,
    AVG(b.ticket_net_paid) AS avg_ticket_paid,
    SUM(b.total_return_loss) AS total_return_loss,
    COUNT(*) AS ticket_count
FROM base b
WHERE b.ticket_net_paid > (
    SELECT AVG(ticket_net_paid)
    FROM base
    WHERE web_site_id = b.web_site_id
)
GROUP BY b.web_site_id, b.cd_gender
HAVING COUNT(*) >= 5
ORDER BY avg_ticket_paid DESC
LIMIT 100
