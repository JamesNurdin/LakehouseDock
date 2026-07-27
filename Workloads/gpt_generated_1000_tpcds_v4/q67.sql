WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_item_sk,
        i.i_product_name,
        s.s_store_name,
        ca.ca_state,
        cd.cd_gender,
        ss.ss_quantity,
        ss.ss_net_paid,
        p.p_promo_name,
        sr.sr_return_quantity,
        CASE WHEN sr.sr_return_quantity IS NOT NULL THEN 'Returned' ELSE 'No Return' END AS store_return_flag,
        inv.inv_quantity_on_hand,
        ws.ws_quantity AS web_quantity,
        ws.ws_net_paid AS web_net_paid,
        wr.wr_return_quantity,
        r.r_reason_desc AS store_return_reason,
        wr_reason.r_reason_desc AS web_return_reason,
        wp.wp_url,
        web_site.web_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                             AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                            AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason wr_reason ON wr.wr_reason_sk = wr_reason.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'M'
      AND i.i_color = 'BLUE'
      AND s.s_gmt_offset BETWEEN -5.00 AND -4.00
      AND p.p_discount_active = 'Y'
)
SELECT
    d_year,
    i_product_name,
    s_store_name,
    ca_state,
    cd_gender,
    p_promo_name,
    store_return_flag,
    SUM(ss_quantity) AS total_store_qty,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(web_quantity) AS total_web_qty,
    SUM(web_net_paid) AS total_web_sales,
    SUM(inv_quantity_on_hand) AS total_inventory,
    SUM(CASE WHEN store_return_flag = 'Returned' THEN sr_return_quantity ELSE 0 END) AS total_store_returns,
    SUM(CASE WHEN wr_return_quantity IS NOT NULL THEN wr_return_quantity ELSE 0 END) AS total_web_returns,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_paid) + SUM(web_net_paid) DESC) AS sales_rank
FROM joined_data
GROUP BY
    d_year,
    i_product_name,
    s_store_name,
    ca_state,
    cd_gender,
    p_promo_name,
    store_return_flag
ORDER BY d_year DESC, sales_rank ASC
LIMIT 100
