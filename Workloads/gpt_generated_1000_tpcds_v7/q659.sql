WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_addr_sk,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        p.p_channel_email,
        ca.ca_state,
        cr.cr_return_amount,
        cr.cr_order_number,
        w.w_state
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2000
      AND p.p_channel_email = 'Y'
      AND ca.ca_state = 'CA'
      AND s.s_state = 'CA'
      AND w.w_state = 'CA'
),
agg1 AS (
    SELECT
        s_store_name,
        p_promo_name,
        d_year,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        COUNT(DISTINCT ss_net_paid) AS sales_transactions,
        COUNT(DISTINCT cr_order_number) AS return_transactions
    FROM base
    GROUP BY s_store_name, p_promo_name, d_year
)
SELECT
    p_promo_name,
    AVG(total_sales) AS avg_sales_per_store,
    SUM(total_returns) AS total_returns_all,
    SUM(total_sales) AS grand_total_sales
FROM agg1
GROUP BY p_promo_name
HAVING SUM(total_sales) > 100000
ORDER BY avg_sales_per_store DESC
LIMIT 20
