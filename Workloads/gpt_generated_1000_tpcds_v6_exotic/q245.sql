WITH
    d_store AS (
        SELECT * FROM date_dim WHERE d_year = 2000
    ),
    d_ss AS (
        SELECT * FROM date_dim WHERE d_year = 2000
    ),
    d_sr AS (
        SELECT * FROM date_dim WHERE d_year = 2000
    ),
    d_cc AS (
        SELECT * FROM date_dim WHERE d_year = 2000
    ),
    d_cs AS (
        SELECT * FROM date_dim WHERE d_year = 2000
    ),
    d_cr AS (
        SELECT * FROM date_dim WHERE d_year = 2000
    ),
    d_ws AS (
        SELECT * FROM date_dim WHERE d_year = 2000
    )
SELECT
    s.s_store_name,
    s.s_state,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) AS total_profit,
    RANK() OVER (PARTITION BY s.s_state ORDER BY (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) DESC) AS profit_rank_state
FROM store s
JOIN d_store ds               ON s.s_closed_date_sk = ds.d_date_sk
JOIN store_sales ss            ON ss.ss_store_sk = s.s_store_sk
JOIN d_ss dss                  ON ss.ss_sold_date_sk = dss.d_date_sk
JOIN store_returns sr          ON sr.sr_store_sk = s.s_store_sk
JOIN d_sr dsr                  ON sr.sr_returned_date_sk = dsr.d_date_sk
JOIN call_center cc            ON cc.cc_closed_date_sk = ds.d_date_sk
JOIN d_cc dcc                  ON cc.cc_closed_date_sk = dcc.d_date_sk
JOIN catalog_sales cs          ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN d_cs dcs                  ON cs.cs_sold_date_sk = dcs.d_date_sk
JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
JOIN d_cr dcr                  ON cr.cr_returned_date_sk = dcr.d_date_sk
JOIN web_sales ws              ON ws.ws_bill_customer_sk = ss.ss_customer_sk
JOIN d_ws dws                  ON ws.ws_sold_date_sk = dws.d_date_sk
JOIN customer c                ON c.c_customer_sk = ss.ss_customer_sk
JOIN customer_address ca       ON ca.ca_address_sk = ss.ss_addr_sk
JOIN customer_demographics cd  ON cd.cd_demo_sk = ss.ss_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
JOIN ship_mode sm              ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
    AND sm.sm_type = 'AIR'
    AND cc.cc_name LIKE '%East%'
    AND s.s_state = 'CA'
    AND ds.d_year = 2000
    AND dss.d_year = 2000
    AND dsr.d_year = 2000
    AND dcs.d_year = 2000
    AND dws.d_year = 2000
GROUP BY
    s.s_store_name,
    s.s_state
ORDER BY total_profit DESC
LIMIT 100
