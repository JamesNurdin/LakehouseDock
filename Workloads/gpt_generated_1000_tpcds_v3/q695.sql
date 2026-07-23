/* Goal: Analyze average sales, profit, and return metrics per store, state, and catalog department, combining store and web channels, after applying multiple demographic, location, and promotion filters. */
WITH base AS (
    SELECT
        td.t_hour,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_return_amt,
        wr.wr_net_loss,
        s.s_store_name,
        s.s_state,
        cp.cp_department
    FROM tpcds.time_dim td
    INNER JOIN tpcds.store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    INNER JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
    INNER JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    INNER JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND cd.cd_education_status IN ('College', '4 yr Degree')
        AND hd.hd_buy_potential = 'Medium'
        AND ca.ca_location_type = 'apartment'
        AND p.p_discount_active = 'Y'
        AND s.s_state = 'CA'
        AND we.web_country = 'United States'
),
store_agg AS (
    SELECT
        s_store_name,
        s_state,
        cp_department,
        t_hour,
        SUM(ss_ext_sales_price) AS sales_amount,
        SUM(ss_net_profit) AS profit,
        SUM(cr_return_amount) AS return_amount,
        SUM(cr_net_loss) AS loss_amount
    FROM base
    GROUP BY s_store_name, s_state, cp_department, t_hour
),
web_agg AS (
    SELECT
        s_store_name,
        s_state,
        cp_department,
        t_hour,
        SUM(ws_ext_sales_price) AS sales_amount,
        SUM(ws_net_profit) AS profit,
        SUM(wr_return_amt) AS return_amount,
        SUM(wr_net_loss) AS loss_amount
    FROM base
    GROUP BY s_store_name, s_state, cp_department, t_hour
),
combined AS (
    SELECT s_store_name, s_state, cp_department, t_hour, sales_amount, profit, return_amount, loss_amount FROM store_agg
    UNION ALL
    SELECT s_store_name, s_state, cp_department, t_hour, sales_amount, profit, return_amount, loss_amount FROM web_agg
)
SELECT
    s_store_name,
    s_state,
    cp_department,
    AVG(sales_amount) AS avg_sales_amount,
    AVG(profit) AS avg_profit,
    AVG(return_amount) AS avg_return_amount,
    AVG(loss_amount) AS avg_loss_amount
FROM combined
GROUP BY s_store_name, s_state, cp_department
HAVING AVG(sales_amount) > 10000
ORDER BY avg_sales_amount DESC
LIMIT 100
