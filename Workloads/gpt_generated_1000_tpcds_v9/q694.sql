WITH enriched_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name,
        d_sales.d_year AS sales_year,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
        COALESCE(sr.sr_net_loss, 0) AS return_net_loss,
        COALESCE(cr.cr_return_quantity, 0) AS catalog_return_quantity,
        COALESCE(cr.cr_net_loss, 0) AS catalog_return_net_loss,
        COALESCE(wr.wr_return_quantity, 0) AS web_return_quantity,
        COALESCE(wr.wr_net_loss, 0) AS web_return_net_loss,
        (
            SELECT COUNT(*)
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_start_date_sk <= d_sales.d_date_sk
              AND p2.p_end_date_sk >= d_sales.d_date_sk
        ) AS promo_active_count
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion promo_ss
        ON ss.ss_promo_sk = promo_ss.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
           AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN catalog_sales cs
        ON ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion promo_cs
        ON cs.cs_promo_sk = promo_cs.p_promo_sk
    LEFT JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_sales.d_year = 2001
      AND t_sales.t_shift = 'first'
)
SELECT
    s_store_sk,
    s_store_name,
    i_item_sk,
    i_product_name,
    sales_year,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(return_quantity) AS total_return_quantity,
    SUM(return_net_loss) AS total_return_loss,
    SUM(promo_active_count) AS total_active_promotions
FROM enriched_sales
GROUP BY
    s_store_sk,
    s_store_name,
    i_item_sk,
    i_product_name,
    sales_year
HAVING
    (SUM(ss_net_profit) - SUM(return_net_loss)) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
