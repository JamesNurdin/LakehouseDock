WITH joined_data AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        ws.ws_net_profit AS ws_net_profit,
        cs.cs_order_number,
        c.c_customer_id,
        td.t_sub_shift,
        cc.cc_market_manager,
        cp.cp_department,
        w.w_warehouse_name,
        p.p_promo_name,
        wp.wp_type
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        sr.sr_fee > 50
        AND ws.ws_ext_tax BETWEEN 30 AND 200
        AND td.t_sub_shift = 'morning'
        AND i.i_current_price BETWEEN 100 AND 500
        AND cc.cc_market_manager = 'John Doe'
        AND cp.cp_department = 'Sports'
        AND w.w_warehouse_name = 'Warehouse_1'
),
agg AS (
    SELECT
        s_store_name,
        i_category,
        i_brand,
        SUM(sr_net_loss) AS total_sr_net_loss,
        SUM(cr_net_loss) AS total_cr_net_loss,
        SUM(ws_net_profit) AS total_ws_net_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM joined_data
    GROUP BY GROUPING SETS (
        (s_store_name, i_category, i_brand),
        (s_store_name, i_category),
        (s_store_name),
        ()
    )
)
SELECT
    s_store_name,
    i_category,
    i_brand,
    total_sr_net_loss,
    total_cr_net_loss,
    total_ws_net_profit,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_ws_net_profit DESC) AS profit_rank
FROM agg
ORDER BY s_store_name, i_category, i_brand
LIMIT 100
