WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        ss_store_sk,
        ss_hdemo_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_quantity,
        ss_net_paid,
        ss_ext_discount_amt
    FROM tpcds.store_sales
),
cs AS (
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_bill_hdemo_sk,
        cs_call_center_sk,
        cs_warehouse_sk,
        cs_promo_sk,
        cs_net_paid,
        cs_ext_discount_amt
    FROM tpcds.catalog_sales
),
wr AS (
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_refunded_hdemo_sk,
        wr_web_page_sk,
        wr_return_amt,
        wr_return_tax
    FROM tpcds.web_returns
)
SELECT
    d.d_year,
    s.s_state,
    i.i_brand,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
    SUM(ss.ss_quantity) AS total_store_quantity,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    MIN(ss.ss_net_paid) AS min_store_net_paid,
    MAX(ss.ss_net_paid) AS max_store_net_paid
FROM ss
JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, s.s_state, i.i_brand, p.p_promo_name
ORDER BY total_store_net_paid DESC
LIMIT 100
