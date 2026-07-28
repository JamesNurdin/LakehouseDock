WITH raw_data AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        ca.ca_state,
        ss.ss_net_paid,
        sr.sr_net_loss,
        cust.c_customer_id,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        r.r_reason_desc,
        cc.cc_name,
        ws.web_name,
        wp.wp_url,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM tpcds.date_dim d
    JOIN tpcds.customer cust
        ON cust.c_first_sales_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON cust.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.customer_address ca
        ON cust.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_customer_sk = cust.c_customer_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_customer_sk = cust.c_customer_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = cust.c_customer_sk
    JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_customer_sk = cust.c_customer_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 30000
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 2
),
agg1 AS (
    SELECT
        p_promo_name,
        d_year,
        ca_state,
        SUM(ss_net_paid) AS total_sales,
        SUM(sr_net_loss) AS total_returns,
        COUNT(DISTINCT c_customer_id) AS uniq_customers,
        AVG(CASE WHEN hd_vehicle_count > 0 THEN 1 ELSE 0 END) AS vehicle_owner_rate,
        CASE WHEN SUM(ss_net_paid) > 500000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM raw_data
    GROUP BY p_promo_name, d_year, ca_state
)
SELECT
    sales_category,
    d_year,
    COUNT(*) AS promo_count,
    AVG(total_sales) AS avg_total_sales,
    SUM(total_returns) AS sum_total_returns
FROM agg1
WHERE total_sales > 100000
GROUP BY sales_category, d_year
HAVING AVG(total_sales) > 200000
ORDER BY avg_total_sales DESC
LIMIT 100
