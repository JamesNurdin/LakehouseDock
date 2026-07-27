WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        sm.sm_type,
        wsite.web_name,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        wr.wr_net_loss,
        cc.cc_state,
        p.p_discount_active
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON i.i_item_sk = ss.ss_item_sk
    JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN tpcds.promotion p
        ON p.p_promo_sk = ss.ss_promo_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_site wsite
        ON wsite.web_site_sk = ws.ws_web_site_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_color IN ('purple', 'rosy')
      AND sm.sm_type = 'OVERNIGHT'
      AND wsite.web_class = 'Unknown'
)
SELECT
    d_year,
    i_category,
    sm_type,
    web_name,
    COUNT(DISTINCT ss_ticket_number) AS store_transactions,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(cs_quantity) AS total_quantity_sold,
    CASE
        WHEN SUM(cs_ext_sales_price) > 1000000 THEN 'High'
        ELSE 'Low'
    END AS sales_volume_category
FROM base
GROUP BY d_year, i_category, sm_type, web_name
ORDER BY total_catalog_sales DESC
LIMIT 100
