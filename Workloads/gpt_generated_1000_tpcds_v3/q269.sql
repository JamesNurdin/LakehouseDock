WITH all_data AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        s.s_store_name,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count,
        ca.ca_state,
        t.t_hour AS sale_hour,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_net_paid,
        ws.ws_net_profit,
        r.r_reason_desc,
        wp.wp_autogen_flag,
        wp.wp_link_count,
        inv.inv_quantity_on_hand
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE cd.cd_purchase_estimate >= 8000
      AND cd.cd_dep_employed_count = 1
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_link_count > 15
      AND inv.inv_date_sk = 2451074
)
SELECT
    i_category,
    s_store_name,
    CASE WHEN i_current_price > 50 THEN 'High' ELSE 'Low' END AS price_category,
    COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
    SUM(ss_net_paid) AS total_store_sales_net_paid,
    SUM(ss_net_profit) AS total_store_sales_net_profit,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(sr_net_loss) AS total_store_return_net_loss,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(cr_net_loss) AS total_catalog_return_net_loss,
    SUM(ws_net_paid) AS total_web_sales_net_paid,
    SUM(ws_net_profit) AS total_web_sales_net_profit,
    SUM(CASE WHEN r_reason_desc = 'Damaged' THEN sr_return_amt ELSE 0 END) AS damaged_return_amount,
    MIN(sale_hour) AS earliest_sale_hour,
    MAX(sale_hour) AS latest_sale_hour
FROM all_data
GROUP BY
    i_category,
    s_store_name,
    CASE WHEN i_current_price > 50 THEN 'High' ELSE 'Low' END
HAVING SUM(ss_net_paid) > 100000
ORDER BY total_store_sales_net_paid DESC
LIMIT 20
