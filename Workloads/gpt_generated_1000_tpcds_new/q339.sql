/* goal: Identify the top‑earning customers per store, distinguishing sales from returns, using a blend of UNION, INTERSECT and window ranking while applying several business filters */
WITH unified AS (
    /* First branch – afternoon sales in CA with active promotions */
    SELECT
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        p.p_promo_name,
        r.r_reason_desc,
        td.t_time_id,
        ss.ss_net_paid,
        sr.sr_return_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE td.t_am_pm = 'PM'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND c.c_birth_year BETWEEN 1960 AND 1970

    UNION

    /* Second branch – morning sales in TX with inactive promotions and a specific birth day */
    SELECT
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        p.p_promo_name,
        r.r_reason_desc,
        td.t_time_id,
        ss.ss_net_paid,
        sr.sr_return_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE td.t_am_pm = 'AM'
      AND s.s_state = 'TX'
      AND p.p_discount_active = 'N'
      AND c.c_birth_day = 13
),
filtered AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        p.p_promo_name,
        r.r_reason_desc,
        td.t_time_id,
        ss.ss_net_paid,
        sr.sr_return_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE s.s_gmt_offset >= 0
      AND td.t_hour >= 12
      AND p.p_channel_email = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    u.s_store_id,
    u.s_store_name,
    u.c_customer_id,
    u.c_first_name,
    u.c_last_name,
    u.cd_gender,
    u.ca_city,
    u.p_promo_name,
    u.r_reason_desc,
    u.t_time_id,
    u.ss_net_paid,
    CASE WHEN u.sr_return_quantity IS NOT NULL AND u.sr_return_quantity > 0 THEN 'Return' ELSE 'Sale' END AS transaction_type,
    ROW_NUMBER() OVER (PARTITION BY u.s_store_id ORDER BY u.ss_net_paid DESC) AS rn
FROM (
    SELECT * FROM unified
    INTERSECT
    SELECT * FROM filtered
) u
ORDER BY rn DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
