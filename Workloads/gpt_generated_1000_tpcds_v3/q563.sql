WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_sales_price) AS catalog_sales_total,
        COUNT(*) AS catalog_orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count > 0
      AND cs.cs_sales_price > 50
    GROUP BY cs.cs_bill_customer_sk
),
cr AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE cr.cr_return_amount > 0
),
ss_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_sales_price) AS store_sales_total,
        COUNT(*) AS store_transactions
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ss.ss_sales_price > 30
    GROUP BY ss.ss_customer_sk
),
sr AS (
    SELECT
        sr.sr_ticket_number,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM tpcds.store_returns sr
    JOIN tpcds.store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    GROUP BY sr.sr_ticket_number
),
ws_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_sales_price) AS web_sales_total,
        COUNT(*) AS web_transactions
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sales_price > 40
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs_agg.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(ss_agg.store_net_profit, 0) AS store_net_profit,
    COALESCE(ws_agg.web_net_profit, 0) AS web_net_profit,
    COALESCE(cs_agg.catalog_net_profit, 0) + COALESCE(ss_agg.store_net_profit, 0) + COALESCE(ws_agg.web_net_profit, 0) AS total_net_profit,
    CASE
        WHEN COALESCE(cs_agg.catalog_net_profit, 0) + COALESCE(ss_agg.store_net_profit, 0) + COALESCE(ws_agg.web_net_profit, 0) > 5000 THEN 'High'
        WHEN COALESCE(cs_agg.catalog_net_profit, 0) + COALESCE(ss_agg.store_net_profit, 0) + COALESCE(ws_agg.web_net_profit, 0) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY COALESCE(cs_agg.catalog_net_profit, 0) + COALESCE(ss_agg.store_net_profit, 0) + COALESCE(ws_agg.web_net_profit, 0) DESC) AS profit_rank
FROM tpcds.customer c
LEFT JOIN cs_agg ON c.c_customer_sk = cs_agg.cust_sk
LEFT JOIN ss_agg ON c.c_customer_sk = ss_agg.cust_sk
LEFT JOIN ws_agg ON c.c_customer_sk = ws_agg.cust_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1950 AND 1990
  AND c.c_email_address LIKE '%@example.com'
ORDER BY profit_rank
LIMIT 10
