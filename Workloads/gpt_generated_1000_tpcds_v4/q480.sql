WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(cr.cr_refunded_cash) AS catalog_refund_total,
        SUM(sr.sr_net_loss) AS store_return_loss,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_returned_date_sk = d.d_date_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                           AND ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                             AND inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1300
        AND i.i_brand = 'Brand#23'
        AND p.p_discount_active = 'Y'
        AND wp.wp_image_count > 3
        AND inv.inv_quantity_on_hand < 100
        AND ss.ss_quantity >= 5
        AND ws.ws_quantity >= 2
        AND cr.cr_refunded_cash > 1000
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        p.p_promo_name
    HAVING
        SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    p_promo_name,
    store_sales_total,
    web_sales_total,
    catalog_refund_total,
    store_return_loss,
    avg_inventory,
    web_orders,
    CASE WHEN store_return_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS return_status,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY store_sales_total DESC) AS rank_by_store_sales
FROM agg
ORDER BY store_sales_total DESC, d_year, d_month_seq
LIMIT 100
