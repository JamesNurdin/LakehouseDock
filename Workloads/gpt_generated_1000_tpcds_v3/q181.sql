/* Goal: Rank product categories by combined net profit from catalog and web sales for the year 2001, while accounting for returns, inventory on hand, promotions, and stores operating in California. */
WITH
    inventory_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    ),
    catalog_sales_agg AS (
        SELECT cs.cs_item_sk AS item_sk,
               cs.cs_catalog_page_sk AS catalog_page_sk,
               cs.cs_bill_addr_sk AS bill_addr_sk,
               cs.cs_bill_hdemo_sk AS bill_hdemo_sk,
               cs.cs_ship_addr_sk AS ship_addr_sk,
               cs.cs_ship_hdemo_sk AS ship_hdemo_sk,
               SUM(cs.cs_net_profit) AS cat_net_profit,
               SUM(cs.cs_quantity) AS cat_quantity
        FROM catalog_sales cs
        JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
        JOIN time_dim t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
        WHERE d_cs_sold.d_year = 2001
        GROUP BY cs.cs_item_sk,
                 cs.cs_catalog_page_sk,
                 cs.cs_bill_addr_sk,
                 cs.cs_bill_hdemo_sk,
                 cs.cs_ship_addr_sk,
                 cs.cs_ship_hdemo_sk
    ),
    web_sales_agg AS (
        SELECT ws.ws_item_sk AS item_sk,
               ws.ws_web_page_sk AS web_page_sk,
               ws.ws_web_site_sk AS web_site_sk,
               ws.ws_bill_addr_sk AS bill_addr_sk,
               ws.ws_bill_hdemo_sk AS bill_hdemo_sk,
               ws.ws_ship_addr_sk AS ship_addr_sk,
               ws.ws_ship_hdemo_sk AS ship_hdemo_sk,
               SUM(ws.ws_net_profit) AS web_net_profit,
               SUM(ws.ws_quantity) AS web_quantity
        FROM web_sales ws
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        WHERE d_ws_sold.d_year = 2001
        GROUP BY ws.ws_item_sk,
                 ws.ws_web_page_sk,
                 ws.ws_web_site_sk,
                 ws.ws_bill_addr_sk,
                 ws.ws_bill_hdemo_sk,
                 ws.ws_ship_addr_sk,
                 ws.ws_ship_hdemo_sk
    ),
    catalog_returns_agg AS (
        SELECT cr.cr_item_sk AS item_sk,
               SUM(cr.cr_net_loss) AS total_cr_net_loss,
               COUNT(*) AS cr_return_cnt
        FROM catalog_returns cr
        GROUP BY cr.cr_item_sk
    ),
    web_returns_agg AS (
        SELECT wr.wr_item_sk AS item_sk,
               SUM(wr.wr_net_loss) AS total_wr_net_loss,
               COUNT(*) AS wr_return_cnt
        FROM web_returns wr
        GROUP BY wr.wr_item_sk
    ),
    catalog_return_reason AS (
        SELECT cr.cr_item_sk AS item_sk,
               MIN(r.r_reason_desc) AS sample_cr_reason_desc
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        GROUP BY cr.cr_item_sk
    ),
    web_return_reason AS (
        SELECT wr.wr_item_sk AS item_sk,
               MIN(r.r_reason_desc) AS sample_wr_reason_desc
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        GROUP BY wr.wr_item_sk
    ),
    promotion_filtered AS (
        SELECT p.p_item_sk AS item_sk,
               p.p_promo_sk,
               p.p_discount_active,
               d_start.d_date_sk AS start_date_sk,
               d_end.d_date_sk AS end_date_sk
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
        WHERE p.p_discount_active = 'Y'
    ),
    promo_agg AS (
        SELECT item_sk,
               COUNT(*) AS promo_cnt
        FROM promotion_filtered
        GROUP BY item_sk
    ),
    store_agg AS (
        SELECT s.s_state,
               COUNT(*) AS store_cnt,
               MAX(s.s_gmt_offset) AS max_gmt_offset
        FROM store s
        JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
        WHERE s.s_state = 'CA'
        GROUP BY s.s_state
    )
SELECT
    i.i_category,
    i.i_class,
    SUM(cs_agg.cat_net_profit) AS total_catalog_net_profit,
    SUM(ws_agg.web_net_profit) AS total_web_net_profit,
    COALESCE(SUM(cr_agg.total_cr_net_loss), 0) AS total_catalog_return_loss,
    COALESCE(SUM(wr_agg.total_wr_net_loss), 0) AS total_web_return_loss,
    MAX(inv_agg.total_qty_on_hand) AS total_inventory_on_hand,
    MAX(promo_agg.promo_cnt) AS promotion_count,
    store_agg.s_state,
    store_agg.store_cnt,
    MAX(cr_reason.sample_cr_reason_desc) AS sample_catalog_return_reason,
    MAX(wr_reason.sample_wr_reason_desc) AS sample_web_return_reason,
    DENSE_RANK() OVER (
        ORDER BY (SUM(cs_agg.cat_net_profit) + SUM(ws_agg.web_net_profit) - COALESCE(SUM(cr_agg.total_cr_net_loss),0) - COALESCE(SUM(wr_agg.total_wr_net_loss),0)) DESC
    ) AS profit_rank
FROM item i
LEFT JOIN catalog_sales_agg cs_agg ON i.i_item_sk = cs_agg.item_sk
LEFT JOIN web_sales_agg ws_agg ON i.i_item_sk = ws_agg.item_sk
LEFT JOIN catalog_returns_agg cr_agg ON i.i_item_sk = cr_agg.item_sk
LEFT JOIN web_returns_agg wr_agg ON i.i_item_sk = wr_agg.item_sk
LEFT JOIN inventory_agg inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
LEFT JOIN promo_agg ON i.i_item_sk = promo_agg.item_sk
LEFT JOIN catalog_return_reason cr_reason ON i.i_item_sk = cr_reason.item_sk
LEFT JOIN web_return_reason wr_reason ON i.i_item_sk = wr_reason.item_sk
LEFT JOIN catalog_page cp ON cs_agg.catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
LEFT JOIN web_page wp ON ws_agg.web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN web_site ws_site ON ws_agg.web_site_sk = ws_site.web_site_sk
LEFT JOIN customer_address ca_bill ON cs_agg.bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN household_demographics hd_bill ON cs_agg.bill_hdemo_sk = hd_bill.hd_demo_sk
CROSS JOIN store_agg
GROUP BY
    i.i_category,
    i.i_class,
    store_agg.s_state,
    store_agg.store_cnt
ORDER BY profit_rank
LIMIT 100
