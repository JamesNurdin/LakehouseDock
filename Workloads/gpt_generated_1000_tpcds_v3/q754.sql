WITH per_customer AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_state,
        CASE
            WHEN cr.cr_net_loss > 0 THEN 'Loss'
            WHEN cs.cs_net_profit > 0 THEN 'Profit'
            ELSE 'Neutral'
        END AS profit_indicator,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        AVG(cr.cr_net_loss) AS avg_return_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        s.s_rec_start_date >= DATE '2000-01-01'
        AND s.s_rec_end_date <= DATE '2002-12-31'
        AND wp.wp_rec_start_date >= DATE '1999-01-01'
        AND wp.wp_rec_end_date <= DATE '2003-12-31'
        AND ws_site.web_rec_start_date >= DATE '1998-01-01'
        AND ws_site.web_rec_end_date <= DATE '2004-12-31'
        AND ca.ca_country = 'United States'
        AND p.p_discount_active = 'Y'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_state,
        CASE
            WHEN cr.cr_net_loss > 0 THEN 'Loss'
            WHEN cs.cs_net_profit > 0 THEN 'Profit'
            ELSE 'Neutral'
        END
)
SELECT
    profit_indicator,
    COUNT(*) AS num_customers,
    SUM(catalog_sales_total) AS total_catalog_sales,
    SUM(store_sales_total) AS total_store_sales,
    SUM(web_sales_total) AS total_web_sales,
    AVG(avg_return_loss) AS avg_return_loss
FROM per_customer
GROUP BY profit_indicator
HAVING SUM(catalog_sales_total) > 100000
ORDER BY total_catalog_sales DESC
LIMIT 100
