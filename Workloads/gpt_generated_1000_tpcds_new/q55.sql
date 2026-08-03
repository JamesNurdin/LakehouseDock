WITH agg AS (
    SELECT i.i_item_id,
           i.i_category,
           w.w_state,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(sr.sr_return_amt_inc_tax) AS total_return,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN tpcds.item i ON i.i_item_sk = inv.inv_item_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t_ss ON t_ss.t_time_sk = ss.ss_sold_time_sk
    JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN tpcds.customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t_sr ON t_sr.t_time_sk = sr.sr_return_time_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t_wr ON t_wr.t_time_sk = wr.wr_returned_time_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id IN (3001002, 8007005)
      AND w.w_state = 'SC'
      AND cc.cc_gmt_offset = -6.00
      AND hd.hd_vehicle_count >= 1
      AND ca.ca_gmt_offset = -5.00
    GROUP BY i.i_item_id, i.i_category, w.w_state

    UNION DISTINCT

    SELECT i.i_item_id,
           i.i_category,
           w.w_state,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(sr.sr_return_amt_inc_tax) AS total_return,
           SUM(ss.ss_net_profit) AS total_profit,
           SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN tpcds.item i ON i.i_item_sk = inv.inv_item_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t_ss ON t_ss.t_time_sk = ss.ss_sold_time_sk
    JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN tpcds.customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t_sr ON t_sr.t_time_sk = sr.sr_return_time_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim t_wr ON t_wr.t_time_sk = wr.wr_returned_time_sk
    WHERE d.d_year = 2002
      AND i.i_brand_id = 5002002
      AND w.w_state = 'MN'
      AND cc.cc_gmt_offset = -7.00
      AND hd.hd_vehicle_count <> 0
      AND ca.ca_gmt_offset = -6.00
    GROUP BY i.i_item_id, i.i_category, w.w_state
)
SELECT agg.i_category,
       agg.w_state,
       SUM(agg.total_sales) AS category_sales,
       AVG(agg.total_profit) AS avg_profit,
       SUM(agg.total_on_hand) AS total_inventory
FROM agg
GROUP BY agg.i_category, agg.w_state
HAVING SUM(agg.total_sales) > 10000
ORDER BY category_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
