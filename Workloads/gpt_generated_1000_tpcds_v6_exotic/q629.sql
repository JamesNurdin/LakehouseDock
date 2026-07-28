WITH base AS (
    SELECT 
        s.s_store_name,
        i.i_category,
        td1.t_hour,
        cs.cs_net_profit,
        ss.ss_net_profit,
        wr.wr_net_loss,
        i.i_current_price,
        i.i_category AS cat
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td1 ON cs.cs_sold_time_sk = td1.t_time_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td2 ON ss.ss_sold_time_sk = td2.t_time_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca_store_addr ON ss.ss_addr_sk = ca_store_addr.ca_address_sk
    JOIN tpcds.customer_demographics cd_store_demo ON ss.ss_cdemo_sk = cd_store_demo.cd_demo_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td3 ON wr.wr_returned_time_sk = td3.t_time_sk
    JOIN tpcds.customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    JOIN tpcds.customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_size = 'large'
)
SELECT 
    b.s_store_name,
    b.i_category,
    b.t_hour,
    SUM(b.cs_net_profit) AS total_catalog_profit,
    SUM(b.ss_net_profit) AS total_store_profit,
    SUM(b.wr_net_loss) AS total_web_return_loss,
    AVG(b.i_current_price) AS avg_item_price,
    (SELECT AVG(ii.i_current_price) FROM tpcds.item ii WHERE ii.i_category = b.i_category) AS avg_category_price
FROM base b
GROUP BY b.s_store_name, b.i_category, b.t_hour
ORDER BY total_catalog_profit DESC
LIMIT 100
