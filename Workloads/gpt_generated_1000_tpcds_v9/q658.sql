WITH base AS (
    SELECT
        d.d_year AS d_year,
        i.i_category,
        i.i_brand,
        ss.ss_net_paid AS ss_net_paid,
        cs.cs_net_paid AS cs_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        sr.sr_return_amt AS sr_return_amt,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        cs.cs_quantity AS cs_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_promo_sk = p.p_promo_sk
        AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_site wsit
        ON wsit.web_open_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_web_page_sk = wp.wp_web_page_sk
        AND ws.ws_web_site_sk = wsit.web_site_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND p.p_channel_catalog = 'N'
),
agg AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(sr_return_amt) AS total_returns,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        SUM(cs_quantity) AS total_quantity,
        CASE WHEN SUM(cs_quantity) > 10 THEN 'High' ELSE 'Low' END AS quantity_flag
    FROM base
    GROUP BY d_year, i_category, i_brand
)
SELECT
    d_year,
    i_category,
    i_brand,
    total_store_sales,
    total_catalog_sales,
    total_web_sales,
    total_returns,
    total_quantity_on_hand,
    quantity_flag,
    RANK() OVER (ORDER BY total_store_sales + total_catalog_sales + total_web_sales DESC) AS sales_rank
FROM agg
ORDER BY sales_rank
LIMIT 100
