WITH base AS (
    SELECT
        d1.d_date AS sale_date,
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        sm.sm_code AS ship_mode_code,
        ca_bill.ca_state AS state,
        r.r_reason_desc AS return_reason,
        cs.cs_net_paid AS cs_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        ss.ss_net_paid AS ss_net_paid
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk

    JOIN store_sales ss ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk

    JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN time_dim t3 ON ws.ws_sold_time_sk = t3.t_time_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk

    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d1.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d1.d_year = 2001
      AND sm.sm_code = 'AIR'
      AND p.p_channel_dmail = 'Y'
      AND ca_bill.ca_state = 'CA'
      AND r.r_reason_desc LIKE '%warranty%'
)
SELECT
    sale_date,
    store_name,
    promo_name,
    AVG(total_net_paid) AS avg_total_net_paid,
    COUNT(*) AS cnt
FROM (
    SELECT
        sale_date,
        store_name,
        promo_name,
        (cs_net_paid + ws_net_paid + ss_net_paid) AS total_net_paid
    FROM base
) agg
GROUP BY sale_date, store_name, promo_name
HAVING AVG(total_net_paid) > (
    SELECT AVG(cs2.cs_net_paid) * 1.2
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
ORDER BY avg_total_net_paid DESC
LIMIT 100
