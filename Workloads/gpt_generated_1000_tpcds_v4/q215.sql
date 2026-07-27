WITH joined AS (
   SELECT
       s.s_store_name               AS s_store_name,
       d1.d_year                    AS d_year,
       sm.sm_type                   AS sm_type,
       ss.ss_ext_sales_price        AS ss_ext_sales_price,
       ws.ws_ext_sales_price        AS ws_ext_sales_price,
       ss.ss_net_profit             AS ss_net_profit,
       ws.ws_net_profit             AS ws_net_profit,
       i.inv_quantity_on_hand       AS inv_quantity_on_hand,
       ca1.ca_state                 AS ca_state,
       t1.t_am_pm                   AS t_am_pm,
       r.r_reason_desc              AS r_reason_desc,
       cc.cc_gmt_offset             AS cc_gmt_offset
   FROM store_sales ss
   JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
   JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
   JOIN customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
   JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
   JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN call_center cc ON cc.cc_closed_date_sk = d1.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN inventory i ON i.inv_date_sk = d1.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d2 ON s.s_closed_date_sk = d2.d_date_sk
   JOIN date_dim d3 ON cc.cc_open_date_sk = d3.d_date_sk
   WHERE d1.d_year = 2001
     AND ca1.ca_state = 'CA'
     AND sm.sm_type = 'AIR'
     AND r.r_reason_desc LIKE '%Lost%'
     AND cc.cc_gmt_offset = -5.00
     AND t1.t_am_pm = 'PM'
),
agg_by_store AS (
   SELECT
       s_store_name,
       d_year,
       sm_type,
       SUM(ss_ext_sales_price)  AS store_sales_amount,
       SUM(ws_ext_sales_price)  AS web_sales_amount,
       SUM(inv_quantity_on_hand) AS total_inventory,
       SUM(ss_net_profit) + SUM(ws_net_profit) AS total_net_profit,
       COUNT(*)                 AS txn_count
   FROM joined
   GROUP BY s_store_name, d_year, sm_type
)
SELECT
   s_store_name,
   d_year,
   sm_type,
   (store_sales_amount + web_sales_amount) AS total_sales,
   total_net_profit / NULLIF(txn_count, 0) AS avg_profit_per_txn,
   total_inventory
FROM agg_by_store
WHERE (store_sales_amount + web_sales_amount) > (
        SELECT AVG(store_sales_amount + web_sales_amount) FROM agg_by_store
      )
ORDER BY total_sales DESC
LIMIT 100
