WITH intersect_stores AS (
        SELECT s1.s_store_id
        FROM store s1
        WHERE s1.s_state = 'CA'
        INTERSECT
        SELECT s2.s_store_id
        FROM store s2
        WHERE s2.s_zip LIKE '9%'
    )
SELECT
    d_cs_sold.d_year,
    s.s_state,
    i.i_category,
    cd_bill.cd_gender,
    SUM(cs.cs_net_paid)            AS total_net_paid,
    SUM(sr.sr_net_loss)            AS total_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM catalog_sales cs
JOIN date_dim d_cs_sold      ON cs.cs_sold_date_sk   = d_cs_sold.d_date_sk
JOIN date_dim d_cs_ship      ON cs.cs_ship_date_sk   = d_cs_ship.d_date_sk
JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p             ON cs.cs_promo_sk       = p.p_promo_sk
JOIN item i                  ON cs.cs_item_sk        = i.i_item_sk
JOIN customer c_bill         ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN inventory inv           ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv          ON inv.inv_date_sk = d_inv.d_date_sk
JOIN store_sales ss          ON ss.ss_item_sk = i.i_item_sk
                                 AND ss.ss_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_ss_sold      ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
JOIN customer c_ss           ON ss.ss_customer_sk   = c_ss.c_customer_sk
JOIN customer_address ca_ss  ON ss.ss_addr_sk       = ca_ss.ca_address_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk  = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN promotion p_ss          ON ss.ss_promo_sk      = p_ss.p_promo_sk
JOIN store s                 ON ss.ss_store_sk      = s.s_store_sk
JOIN store_returns sr        ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr_returned  ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
JOIN customer c_sr           ON sr.sr_customer_sk   = c_sr.c_customer_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk   = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr  ON sr.sr_addr_sk       = ca_sr.ca_address_sk
JOIN web_page wp             ON wp.wp_customer_sk   = c_bill.c_customer_sk
JOIN date_dim d_wp_creation  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access    ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
JOIN web_site ws             ON ws.web_open_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_ws_close     ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN intersect_stores ist    ON s.s_store_id = ist.s_store_id
WHERE d_cs_sold.d_year = (
        SELECT MAX(d_year)
        FROM date_dim
        WHERE d_year = 2001
    )
GROUP BY CUBE (d_cs_sold.d_year, s.s_state, i.i_category, cd_bill.cd_gender)
ORDER BY total_net_paid DESC
LIMIT 100
