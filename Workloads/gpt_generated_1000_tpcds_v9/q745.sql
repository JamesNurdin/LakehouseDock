WITH sales_aggregated AS (
    SELECT
        c.c_customer_id,
        p.p_promo_id,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(sr.sr_return_amt) AS store_returns_total,
        SUM(wr.wr_return_amt) AS web_returns_total,
        (
            SUM(cs.cs_net_profit) +
            SUM(ss.ss_net_profit) +
            SUM(ws.ws_net_profit) -
            COALESCE(SUM(sr.sr_net_loss), 0) -
            COALESCE(SUM(wr.wr_net_loss), 0)
        ) AS net_profit
    FROM
        time_dim t
        JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE
        t.t_hour BETWEEN 8 AND 17
        AND cp.cp_department = 'Electronics'
        AND p.p_discount_active = 'Y'
        AND c.c_preferred_cust_flag = 'Y'
        AND hd.hd_buy_potential = '1001-5000'
    GROUP BY
        c.c_customer_id,
        p.p_promo_id
)
SELECT
    c_customer_id,
    p_promo_id,
    catalog_sales_total,
    store_sales_total,
    web_sales_total,
    (catalog_sales_total + store_sales_total + web_sales_total) AS total_sales,
    net_profit,
    (net_profit / NULLIF((catalog_sales_total + store_sales_total + web_sales_total), 0)) AS profit_margin
FROM
    sales_aggregated
WHERE
    (catalog_sales_total + store_sales_total + web_sales_total) > 1000
ORDER BY
    profit_margin DESC
LIMIT 100
