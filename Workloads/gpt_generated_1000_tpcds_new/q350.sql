WITH
    full_cr_cc AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_net_loss AS catalog_return_loss,
            cr.cr_call_center_sk,
            cr.cr_warehouse_sk,
            cr.cr_reason_sk,
            cc.cc_call_center_id,
            cc.cc_name AS call_center_name,
            w.w_warehouse_name,
            r.r_reason_desc AS catalog_reason_desc
        FROM catalog_returns cr
        FULL OUTER JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
    ),
    base1 AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_net_paid,
            ss.ss_net_profit,
            d.d_year,
            i.i_item_id,
            i.i_product_name,
            c.c_customer_id,
            cd.cd_gender,
            ca.ca_state,
            inv.inv_quantity_on_hand,
            w.w_warehouse_name,
            wp.wp_url,
            ws.ws_order_number,
            ws.ws_net_paid AS web_net_paid,
            ws.ws_net_profit AS web_net_profit,
            r.r_reason_desc AS store_return_reason,
            sr.sr_net_loss AS store_return_loss,
            wr.wr_net_loss AS web_return_loss,
            fcr.catalog_return_loss,
            fcr.call_center_name,
            ws_site.web_name AS website_name
        FROM store_sales ss
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN warehouse w
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site ws_site
            ON ws.ws_web_site_sk = ws_site.web_site_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN full_cr_cc fcr
            ON fcr.cr_item_sk = i.i_item_sk
            AND fcr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND i.i_brand = 'Brand#12'
          AND ca.ca_country = 'United States'
    ),
    base2 AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_net_paid,
            ss.ss_net_profit,
            d.d_year,
            i.i_item_id,
            i.i_product_name,
            c.c_customer_id,
            cd.cd_gender,
            ca.ca_state,
            inv.inv_quantity_on_hand,
            w.w_warehouse_name,
            wp.wp_url,
            ws.ws_order_number,
            ws.ws_net_paid AS web_net_paid,
            ws.ws_net_profit AS web_net_profit,
            r.r_reason_desc AS store_return_reason,
            sr.sr_net_loss AS store_return_loss,
            wr.wr_net_loss AS web_return_loss,
            fcr.catalog_return_loss,
            fcr.call_center_name,
            ws_site.web_name AS website_name
        FROM store_sales ss
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN warehouse w
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site ws_site
            ON ws.ws_web_site_sk = ws_site.web_site_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN full_cr_cc fcr
            ON fcr.cr_item_sk = i.i_item_sk
            AND fcr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND i.i_brand = 'Brand#23'
          AND ca.ca_state = 'CA'
    ),
    unioned AS (
        SELECT
            ss_ticket_number,
            ss_sold_date_sk,
            ss_net_paid,
            ss_net_profit,
            d_year,
            i_item_id,
            c_customer_id,
            store_return_loss,
            web_return_loss,
            catalog_return_loss,
            call_center_name
        FROM base1
        UNION
        SELECT
            ss_ticket_number,
            ss_sold_date_sk,
            ss_net_paid,
            ss_net_profit,
            d_year,
            i_item_id,
            c_customer_id,
            store_return_loss,
            web_return_loss,
            catalog_return_loss,
            call_center_name
        FROM base2
    ),
    ticket_without_store_return AS (
        SELECT ss_ticket_number
        FROM unioned
        EXCEPT
        SELECT sr_ticket_number
        FROM store_returns
    ),
    final_ranked AS (
        SELECT
            u.ss_ticket_number,
            u.d_year,
            u.i_item_id,
            u.c_customer_id,
            u.ss_net_profit,
            u.store_return_loss,
            u.web_return_loss,
            u.catalog_return_loss,
            u.call_center_name,
            ROW_NUMBER() OVER (PARTITION BY u.c_customer_id ORDER BY u.ss_net_profit DESC) AS rn,
            RANK() OVER (PARTITION BY u.d_year ORDER BY u.ss_net_profit DESC) AS profit_rank
        FROM unioned u
        JOIN ticket_without_store_return tr
            ON u.ss_ticket_number = tr.ss_ticket_number
    )
SELECT
    ss_ticket_number,
    d_year,
    i_item_id,
    c_customer_id,
    ss_net_profit,
    store_return_loss,
    web_return_loss,
    catalog_return_loss,
    call_center_name,
    rn,
    profit_rank
FROM final_ranked
WHERE rn <= 5
ORDER BY profit_rank, ss_net_profit DESC
LIMIT 100
