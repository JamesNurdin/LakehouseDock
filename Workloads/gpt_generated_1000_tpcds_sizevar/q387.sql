WITH
  sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  intersect_store_ids AS (
    SELECT s.s_store_id
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_net_profit > 0
    INTERSECT
    SELECT s2.s_store_id
    FROM store_returns sr
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    WHERE sr.sr_net_loss < 0
  ),
  main_data AS (
    SELECT
        td.t_time_sk,
        td.t_hour,
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        ca_bill.ca_state            AS bill_state,
        ca_ship.ca_state            AS ship_state,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_amount,
        wr.wr_return_amt,
        r_s.r_reason_desc           AS store_return_reason,
        r_c.r_reason_desc           AS catalog_return_reason,
        sm.sm_type,
        cc.cc_name,
        cp.cp_department,
        wp.wp_url,
        LAG(ss.ss_net_paid) OVER (PARTITION BY s.s_store_id ORDER BY td.t_time_sk) AS prev_net_paid,
        SUM(cs.cs_net_paid) OVER (PARTITION BY s.s_store_id ORDER BY td.t_time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
        (SELECT AVG(inv_quantity_on_hand)
         FROM sampled_inventory si
         WHERE si.inv_item_sk = i.i_item_sk) AS avg_inventory_on_hand
    FROM time_dim td
    /* Store Sales branch */
    JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON ss.ss_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ss.ss_addr_sk = ca_ship.ca_address_sk
    /* Catalog Sales branch */
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk AND cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill_cs ON cs.cs_bill_addr_sk = ca_bill_cs.ca_address_sk
    JOIN customer_address ca_ship_cs ON cs.cs_ship_addr_sk = ca_ship_cs.ca_address_sk
    /* Store Returns branch */
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk AND sr.sr_item_sk = i.i_item_sk
    JOIN reason r_s ON sr.sr_reason_sk = r_s.r_reason_sk
    /* Catalog Returns branch */
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk AND cr.cr_item_sk = i.i_item_sk
    JOIN reason r_c ON cr.cr_reason_sk = r_c.r_reason_sk
    /* Web Returns branch */
    JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk AND wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    /* Inventory branch */
    LEFT JOIN sampled_inventory si ON si.inv_item_sk = i.i_item_sk
    /* Additional address dimensions for returns */
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN customer_address ca_sr_addr ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
  )
SELECT
    md.t_time_sk,
    md.t_hour,
    md.s_store_id,
    md.s_store_name,
    md.i_item_id,
    md.i_category,
    md.i_brand,
    md.bill_state,
    md.ship_state,
    md.cs_quantity,
    md.cs_net_paid,
    md.cs_net_profit,
    md.prev_net_paid,
    md.running_net_paid,
    md.avg_inventory_on_hand,
    md.store_return_reason,
    md.catalog_return_reason,
    md.sm_type,
    md.cc_name,
    md.cp_department,
    md.wp_url
FROM main_data md
WHERE md.s_store_id IN (SELECT s_store_id FROM intersect_store_ids)
  AND md.i_category = 'Electronics'
ORDER BY md.running_net_paid DESC
LIMIT 100
