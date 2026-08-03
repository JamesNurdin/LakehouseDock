WITH base AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price AS store_ext_sales,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_fee,
        sr.sr_reason_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_gender,
        d.d_year,
        t.t_hour,
        p.p_discount_active,
        p.p_channel_event,
        s.s_store_name,
        s.s_state,
        inv.inv_quantity_on_hand,
        ws.ws_ext_sales_price AS web_ext_sales,
        wp.wp_type,
        we.web_country,
        r.r_reason_desc
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'TX'
      AND p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
      AND inv.inv_quantity_on_hand > 100
      AND we.web_country = 'United States'
      AND ca.ca_gmt_offset BETWEEN -6.00 AND -5.00
), agg AS (
    SELECT
        ss_store_sk,
        s_store_name,
        d_year,
        SUM(store_ext_sales) AS total_store_sales,
        SUM(web_ext_sales) AS total_web_sales,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT ss_ticket_number) AS ticket_cnt,
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM base
    GROUP BY ss_store_sk, s_store_name, d_year
    HAVING SUM(store_ext_sales) > 10000
)
SELECT
    ss_store_sk,
    s_store_name,
    d_year,
    total_store_sales,
    total_web_sales,
    total_return_amt,
    ticket_cnt,
    avg_inventory,
    total_store_sales / NULLIF(total_web_sales, 0) AS sales_ratio,
    RANK() OVER (ORDER BY total_store_sales DESC) AS sales_rank,
    (SELECT COUNT(*) FROM agg a2 WHERE a2.total_store_sales > agg.total_store_sales) AS higher_stores
FROM agg
ORDER BY total_store_sales DESC
LIMIT 100
