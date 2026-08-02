WITH base AS (
    SELECT
        i.i_category,
        i.i_brand,
        t.t_hour,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(cs.cs_quantity) AS avg_quantity,
        MAX(cs.cs_net_profit) AS max_net_profit,
        SUM(CASE WHEN cs.cs_quantity > 10 THEN cs.cs_ext_sales_price ELSE 0 END) AS bulk_sales,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Full Price' END AS promo_status,
        (
            SELECT SUM(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
              AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
        ) AS total_store_return_amount,
        i.i_item_sk,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    INNER JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    WHERE
        t.t_hour = 12
        AND i.i_brand = 'BrandX'
        AND p.p_discount_active = 'Y'
        AND cs.cs_quantity > 0
    GROUP BY
        i.i_category,
        i.i_brand,
        t.t_hour,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        p.p_discount_active,
        i.i_item_sk,
        cs.cs_sold_date_sk
    HAVING SUM(cs.cs_ext_sales_price) > 5000
)
SELECT
    base.i_category,
    base.i_brand,
    base.t_hour,
    base.cp_department,
    base.p_promo_name,
    base.sm_type,
    base.total_catalog_sales,
    base.total_store_sales,
    base.total_web_sales,
    base.bulk_sales,
    base.promo_status,
    base.total_store_return_amount,
    base.distinct_orders,
    base.avg_quantity,
    base.max_net_profit,
    SUM(base.total_catalog_sales + base.total_store_sales + base.total_web_sales) OVER (PARTITION BY base.i_category) AS category_total_sales,
    ROW_NUMBER() OVER (PARTITION BY base.i_category ORDER BY base.total_catalog_sales DESC) AS category_rank
FROM base
ORDER BY base.total_catalog_sales DESC
LIMIT 100
