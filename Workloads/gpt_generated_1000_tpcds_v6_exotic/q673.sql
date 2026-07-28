WITH distinct_promos AS (
    SELECT DISTINCT p.p_promo_sk, p.p_promo_name
    FROM promotion p
    WHERE p.p_channel_email = 'Y'
),
filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        s.s_store_name,
        i.i_category,
        dp.p_promo_name,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        c.c_customer_id,
        ib.ib_upper_bound,
        cc.cc_name,
        sm.sm_type,
        wp.wp_type,
        cd.cd_education_status
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
                               AND cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN distinct_promos dp ON ss.ss_promo_sk = dp.p_promo_sk
    WHERE s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND ib.ib_upper_bound = 100000
      AND cc.cc_name = 'Call Center 1'
      AND wp.wp_type = 'Content'
      AND cd.cd_education_status = 'College'
),
agg_sales AS (
    SELECT
        s_store_name,
        i_category,
        p_promo_name,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        MIN(ss_sold_date_sk) AS first_sold_date_sk,
        MAX(ss_sold_date_sk) AS last_sold_date_sk
    FROM filtered_sales
    GROUP BY s_store_name, i_category, p_promo_name
)
SELECT
    s_store_name,
    i_category,
    p_promo_name,
    total_sales,
    avg_discount,
    unique_customers,
    first_sold_date_sk,
    last_sold_date_sk,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY s_store_name ORDER BY total_sales ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
