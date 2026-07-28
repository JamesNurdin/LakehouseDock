WITH
    ss AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_store_sk,
            ss.ss_item_sk,
            ss.ss_cdemo_sk,
            ss.ss_addr_sk,
            ss.ss_promo_sk,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_quantity) AS total_quantity,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
        FROM store_sales ss
        GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_item_sk, ss.ss_cdemo_sk, ss.ss_addr_sk, ss.ss_promo_sk
    ),
    wr AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_item_sk,
            wr.wr_refunded_cdemo_sk,
            wr.wr_refunded_addr_sk,
            wr.wr_reason_sk,
            wr.wr_web_page_sk,
            SUM(wr.wr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt
        FROM web_returns wr
        GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk, wr.wr_refunded_cdemo_sk, wr.wr_refunded_addr_sk, wr.wr_reason_sk, wr.wr_web_page_sk
    )
SELECT
    s.s_store_name,
    d_sale.d_year,
    i.i_brand,
    p.p_promo_name,
    COUNT(DISTINCT ca.ca_address_id) AS distinct_customers,
    SUM(ss.total_net_paid) AS sum_net_paid,
    SUM(wr.total_return_amt) AS sum_return_amt,
    SUM(ss.total_quantity) - SUM(wr.return_cnt) AS net_units_sold,
    CASE
        WHEN SUM(ss.total_net_paid) > 100000 THEN 'HIGH'
        WHEN SUM(ss.total_net_paid) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category,
    COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
FROM ss
JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sale.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sale.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sale.d_date_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE d_sale.d_year = 2001
  AND s.s_state = 'TX'
  AND i.i_brand = 'BrandX'
  AND p.p_channel_catalog = 'N'
  AND ca.ca_state = 'CA'
GROUP BY s.s_store_name, d_sale.d_year, i.i_brand, p.p_promo_name
ORDER BY sum_net_paid DESC
LIMIT 100
