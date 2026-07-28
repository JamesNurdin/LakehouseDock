WITH raw AS (
    SELECT
        d_sal.d_year AS year,
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        r_sr.r_reason_desc AS store_return_reason,
        r_cr.r_reason_desc AS catalog_return_reason,
        r_wr.r_reason_desc AS web_return_reason,
        ss.ss_net_profit AS store_sales_profit,
        cr.cr_net_loss AS catalog_return_loss,
        sr.sr_net_loss AS store_return_loss,
        wr.wr_net_loss AS web_return_loss,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        cc.cc_name AS call_center_name,
        wp.wp_url AS web_page_url
    FROM store_sales ss
    JOIN date_dim d_sal ON ss.ss_sold_date_sk = d_sal.d_date_sk
    JOIN time_dim t_sal ON ss.ss_sold_time_sk = t_sal.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    -- Store returns linked to the same sale
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    -- Catalog sales (independent but sharing surrogate keys where possible)
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = ss.ss_item_sk
        AND cs.cs_order_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    LEFT JOIN time_dim t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    LEFT JOIN date_dim d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    LEFT JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer c_cs_bill ON cs.cs_bill_customer_sk = c_cs_bill.c_customer_sk
    LEFT JOIN customer_demographics cd_cs_bill ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
    LEFT JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
    -- Catalog returns linked to catalog sales
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    -- Web returns linked to catalog sales
    LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
        AND wr.wr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
    WHERE
        d_sal.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND ss.ss_quantity > 5
        AND r_sr.r_reason_id IN ('AAAAAAAA', 'AAAAAAAABAAAAAAA')
),
agg AS (
    SELECT
        year,
        store_name,
        promo_name,
        store_return_reason,
        SUM(store_sales_profit) AS total_sales_profit,
        SUM(COALESCE(catalog_return_loss, 0)) AS total_catalog_return_loss,
        SUM(COALESCE(store_return_loss, 0)) AS total_store_return_loss,
        SUM(COALESCE(web_return_loss, 0)) AS total_web_return_loss,
        COUNT(*) AS txn_count
    FROM raw
    GROUP BY GROUPING SETS (
        (year, store_name, promo_name, store_return_reason),
        (year, store_name, promo_name),
        (year, store_name),
        (year),
        ()
    )
)
SELECT
    year,
    AVG(total_sales_profit) AS avg_sales_profit,
    SUM(total_sales_profit) AS sum_sales_profit,
    SUM(total_catalog_return_loss) AS sum_catalog_return_loss,
    SUM(total_store_return_loss) AS sum_store_return_loss,
    SUM(total_web_return_loss) AS sum_web_return_loss,
    SUM(txn_count) AS total_transactions
FROM agg
WHERE total_sales_profit > 1000
GROUP BY year
HAVING SUM(total_sales_profit) > 5000
ORDER BY year DESC
LIMIT 100
