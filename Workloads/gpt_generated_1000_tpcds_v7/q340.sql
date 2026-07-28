WITH base AS (
    SELECT
        d.d_year,
        d.d_date,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_product_name,
        i.i_category_id,
        hd.hd_demo_sk,
        p.p_promo_sk,
        p.p_discount_active,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_profit AS web_net_profit,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        r.r_reason_desc,
        cp.cp_department,
        w.w_warehouse_name,
        wp.wp_type,
        we.web_name,
        wr.wr_net_loss
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
),
agg AS (
    SELECT
        d_year,
        s_state,
        s_store_name,
        SUM(store_net_profit) AS store_profit,
        SUM(web_net_profit) AS web_profit,
        SUM(catalog_sales_amount) AS catalog_sales
    FROM base
    WHERE d_year = 2001
      AND i_category_id IN (1, 4)
      AND s_state = 'CA'
      AND p_discount_active = 'Y'
    GROUP BY d_year, s_state, s_store_name
)
SELECT
    d_year,
    s_state,
    s_store_name,
    store_profit,
    web_profit,
    catalog_sales,
    (store_profit + web_profit + catalog_sales) AS total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY (store_profit + web_profit + catalog_sales) DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
