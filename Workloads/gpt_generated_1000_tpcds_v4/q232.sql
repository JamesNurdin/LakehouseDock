WITH d_sold AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2000
),
 d_ship AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2000
)
SELECT
    d_sold.d_year,
    COUNT(DISTINCT cs.cs_order_number)                       AS catalog_orders,
    SUM(cs.cs_net_paid)                                      AS catalog_sales,
    SUM(ws.ws_net_paid)                                      AS web_sales,
    SUM(ss.ss_net_paid)                                      AS store_sales,
    SUM(cr.cr_net_loss)                                      AS total_return_loss,
    SUM(inv.inv_quantity_on_hand)                            AS total_inventory,
    COUNT(DISTINCT p_start.p_promo_id)                       AS promo_start_count,
    COUNT(DISTINCT p_end.p_promo_id)                         AS promo_end_count
FROM
    d_sold
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sold.d_date_sk
       AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN promotion p_start
        ON p_start.p_start_date_sk = d_sold.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN customer_address ca
        ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship
        ON d_ship.d_date_sk = ws.ws_ship_date_sk
    LEFT JOIN promotion p_end
        ON p_end.p_end_date_sk = d_ship.d_date_sk
WHERE
    d_sold.d_year = 2000
GROUP BY
    d_sold.d_year
ORDER BY
    d_sold.d_year
