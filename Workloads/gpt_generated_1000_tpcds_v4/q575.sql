WITH base AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       s.s_state,
       cc.cc_name,
       sm.sm_type,
       cs.cs_ext_sales_price,
       ws.ws_ext_sales_price,
       cs.cs_order_number,
       ws.ws_order_number,
       cs.cs_net_profit,
       ws.ws_net_profit
   FROM tpcds.date_dim d
   JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 1200 AND 1211
     AND cs.cs_ext_tax > 20
     AND ws.ws_net_profit > 0
     AND s.s_state = 'CA'
     AND cc.cc_gmt_offset = -5.00
)
SELECT
    d_year,
    d_month_seq,
    s_state,
    cc_name,
    sm_type,
    SUM(cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws_ext_sales_price) AS web_sales_amount,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders,
    CASE
        WHEN SUM(cs_net_profit + ws_net_profit) > 1000000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    AVG(cs_net_profit + ws_net_profit) AS avg_profit_per_transaction
FROM base
GROUP BY d_year, d_month_seq, s_state, cc_name, sm_type
HAVING SUM(cs_net_profit + ws_net_profit) > (
    SELECT AVG(cs2.cs_net_profit + ws2.ws_net_profit)
    FROM tpcds.catalog_sales cs2
    JOIN tpcds.web_sales ws2 ON cs2.cs_sold_date_sk = ws2.ws_sold_date_sk
    JOIN tpcds.date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = base.d_year
)
ORDER BY d_year DESC, catalog_sales_amount DESC
LIMIT 100
