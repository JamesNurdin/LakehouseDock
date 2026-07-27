WITH distinct_promos AS (
        SELECT DISTINCT p.p_promo_sk,
               p.p_promo_name
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        WHERE d_start.d_year = 2001
          AND p.p_discount_active = 'Y'
    ),
    sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_brand,
            cp.cp_catalog_number,
            w.w_state,
            ws.web_country,
            SUM(ss.ss_ext_sales_price)                              AS total_sales,
            COUNT(DISTINCT ss.ss_ticket_number)                     AS distinct_tickets,
            AVG(cr.cr_return_amount)                                AS avg_return_amount,
            MIN(cr.cr_return_ship_cost)                             AS min_return_ship_cost,
            MAX(ss.ss_net_paid)                                     AS max_net_paid,
            CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN distinct_promos dp ON p.p_promo_sk = dp.p_promo_sk
        JOIN catalog_returns cr ON ss.ss_item_sk = cr.cr_item_sk
                                 AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
        JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
        JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
        WHERE d.d_year = 2001
          AND i.i_units = 'Carton'
          AND cp.cp_catalog_number IN (4, 16)
          AND w.w_state = 'CA'
          AND ws.web_country = 'US'
          AND p.p_discount_active = 'Y'
        GROUP BY d.d_year,
                 d.d_month_seq,
                 i.i_brand,
                 cp.cp_catalog_number,
                 w.w_state,
                 ws.web_country
    )
SELECT *
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
