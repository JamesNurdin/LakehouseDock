WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_state,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        ws.ws_ext_sales_price,
        wr.wr_return_amt,
        cd.cd_purchase_estimate,
        r.r_reason_desc,
        wp.wp_char_count,
        wsite.web_state
    FROM
        tpcds.date_dim d
        JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
        JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
        JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_order_number = ws.ws_order_number
        JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND cd.cd_purchase_estimate > 5000
        AND r.r_reason_desc LIKE '%damaged%'
        AND wp.wp_char_count > 2000
        AND wsite.web_state = 'CA'
),
agg AS (
    SELECT
        s_store_id AS store_id,
        d_year AS year,
        SUM(ss_ext_sales_price) AS store_sales,
        SUM(sr_return_amt) AS store_returns,
        SUM(ws_ext_sales_price) AS web_sales,
        SUM(wr_return_amt) AS web_returns
    FROM base
    GROUP BY s_store_id, d_year
),
net AS (
    SELECT
        store_id,
        year,
        store_sales,
        store_returns,
        (store_sales - store_returns) AS net_store,
        web_sales,
        web_returns,
        (web_sales - web_returns) AS net_web,
        (store_sales - store_returns + web_sales - web_returns) AS total_net
    FROM agg
    WHERE store_sales > 10000
)
SELECT store_id, year, total_net
FROM net
WHERE total_net > 25000
INTERSECT
SELECT store_id, year, total_net
FROM net
WHERE total_net > 20000
ORDER BY total_net DESC
LIMIT 100
