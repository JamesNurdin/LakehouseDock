WITH base AS (
    SELECT
        d.d_year AS d_year,
        s.s_store_name AS s_store_name,
        i.i_category AS i_category,
        p.p_promo_name AS p_promo_name,
        r.r_reason_desc AS r_reason_desc,
        ss.ss_net_paid AS ss_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        cs.cs_net_paid AS cs_net_paid,
        sr.sr_return_amt AS sr_return_amt,
        c.c_customer_sk AS c_customer_sk
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_item_sk = i.i_item_sk
            AND cs.cs_promo_sk = p.p_promo_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2001
        AND i.i_color = 'red'
        AND w.w_county = 'Franklin Parish'
        AND p.p_discount_active = 'Y'
        AND r.r_reason_desc = 'Wrong size'
)
SELECT
    s_store_name,
    d_year,
    i_category,
    p_promo_name,
    r_reason_desc,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(sr_return_amt) AS total_returns,
    COUNT(DISTINCT c_customer_sk) AS unique_customers
FROM base
GROUP BY
    s_store_name,
    d_year,
    i_category,
    p_promo_name,
    r_reason_desc
HAVING
    SUM(ss_net_paid) > 10000
ORDER BY
    total_store_sales DESC
LIMIT 100
