WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_order_number,
        cc.cc_call_center_sk,
        sm.sm_ship_mode_sk,
        sm.sm_type,
        c.c_customer_sk,
        cd.cd_demo_sk,
        ca.ca_address_sk,
        i.inv_date_sk,
        s.s_store_sk,
        s.s_state,
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        t.t_time_sk,
        t.t_shift,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        w.web_site_sk
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 1999
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND t.t_shift = 'first'
      AND c.c_birth_country = 'United States'
      AND cs.cs_quantity > (SELECT AVG(cs_quantity) FROM tpcds.catalog_sales)
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.store_returns sr2
          WHERE sr2.sr_customer_sk = c.c_customer_sk
            AND sr2.sr_returned_date_sk = d.d_date_sk
      )
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    sm.sm_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(ws.ws_net_paid) AS avg_ws_net_paid,
    MIN(cs.cs_quantity) AS min_quantity,
    MAX(sr.sr_return_quantity) AS max_return_quantity
FROM base
JOIN tpcds.date_dim d ON base.d_date_sk = d.d_date_sk
JOIN tpcds.catalog_sales cs ON base.cs_sold_date_sk = cs.cs_sold_date_sk
JOIN tpcds.store s ON base.s_store_sk = s.s_store_sk
JOIN tpcds.ship_mode sm ON base.sm_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_sales ws ON base.ws_sold_date_sk = ws.ws_sold_date_sk
JOIN tpcds.store_returns sr ON base.sr_returned_date_sk = sr.sr_returned_date_sk
GROUP BY d.d_year, d.d_month_seq, s.s_state, sm.sm_type
ORDER BY total_net_paid DESC
LIMIT 100
