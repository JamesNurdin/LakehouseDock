WITH agg AS (
    SELECT
        d.d_year AS year,
        i.i_brand AS brand,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        MIN(w.w_warehouse_sq_ft) AS min_warehouse_size,
        MAX(p.p_cost) AS max_promo_cost
    FROM
        date_dim d
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
            AND sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_return_time_sk = t.t_time_sk
        JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
            AND wp.wp_customer_sk = c.c_customer_sk
        JOIN web_sales ws ON ws.ws_web_page_sk = wp.wp_web_page_sk
            AND ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        d.d_weekend = 'N'
        AND i.i_class = 'infants'
        AND w.w_state = 'CA'
        AND cp.cp_type = 'catalog'
        AND p.p_discount_active = 'Y'
    GROUP BY
        d.d_year,
        i.i_brand
)
SELECT
    year,
    brand,
    total_catalog_return_amount,
    total_store_net_loss,
    total_web_net_profit,
    distinct_customers,
    min_warehouse_size,
    max_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_web_net_profit DESC) AS profit_rank
FROM agg
ORDER BY year DESC, profit_rank
LIMIT 100
