WITH base AS (
    SELECT
        d.d_year,
        t.t_hour,
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        s.s_store_name,
        we.web_name,
        ss.ss_net_paid AS ss_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        cr.cr_net_loss,
        sm.sm_type,
        i.inv_quantity_on_hand
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 12
      AND c.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
),
web_cust AS (
    SELECT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
store_cust AS (
    SELECT ss.ss_customer_sk AS c_customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
diff_cust AS (
    SELECT c_customer_sk FROM web_cust
    EXCEPT
    SELECT c_customer_sk FROM store_cust
)
SELECT
    b.d_year,
    b.s_store_name AS name,
    SUM(b.ss_net_paid) AS total_net_paid,
    CASE WHEN SUM(b.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
    ROW_NUMBER() OVER (PARTITION BY b.d_year ORDER BY SUM(b.ss_net_paid) DESC) AS rn
FROM base b
JOIN diff_cust dc ON b.c_customer_sk = dc.c_customer_sk
GROUP BY b.d_year, b.s_store_name

UNION

SELECT
    b.d_year,
    b.web_name AS name,
    SUM(b.ws_net_paid) AS total_net_paid,
    CASE WHEN SUM(b.ws_net_paid) < 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
    ROW_NUMBER() OVER (PARTITION BY b.d_year ORDER BY SUM(b.ws_net_paid) DESC) AS rn
FROM base b
GROUP BY b.d_year, b.web_name

ORDER BY rn, d_year
LIMIT 100
