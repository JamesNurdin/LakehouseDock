WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number
)
SELECT
    d_sale.d_year,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    cd.cd_gender,
    ca.ca_state,
    p.p_promo_name,
    w.w_warehouse_name,
    cc.cc_company,
    SUM(base.total_sales) AS sum_sales,
    SUM(base.total_qty) AS sum_qty,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
    CASE WHEN EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_creation_date_sk = d_sale.d_date_sk
          AND wp.wp_type = 'home'
    ) THEN 'Y' ELSE 'N' END AS visited_web_home
FROM base_sales base
JOIN date_dim d_sale
    ON base.ss_sold_date_sk = d_sale.d_date_sk
JOIN item i
    ON base.ss_item_sk = i.i_item_sk
JOIN customer c
    ON base.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON base.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON base.ss_addr_sk = ca.ca_address_sk
JOIN promotion p
    ON base.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = base.ss_ticket_number
LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sale.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sale.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
LEFT JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sale.d_date_sk
LEFT JOIN web_page wp2
    ON wp2.wp_creation_date_sk = d_sale.d_date_sk
   AND wp2.wp_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca2
    ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
WHERE d_sale.d_year = 2000
  AND i.i_current_price > 10
  AND ca.ca_country = 'United States'
GROUP BY
    d_sale.d_year,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    cd.cd_gender,
    ca.ca_state,
    p.p_promo_name,
    w.w_warehouse_name,
    cc.cc_company,
    CASE WHEN EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_creation_date_sk = d_sale.d_date_sk
          AND wp.wp_type = 'home'
    ) THEN 'Y' ELSE 'N' END
ORDER BY sum_sales DESC
LIMIT 100
