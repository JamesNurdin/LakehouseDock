WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        ss.ss_ext_sales_price,
        sr.sr_net_loss,
        cs.cs_ext_sales_price AS cs_sales,
        p.p_discount_active,
        ib.ib_upper_bound,
        cc.cc_name,
        w.w_state,
        ca.ca_country,
        ws.web_name
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_birth_year BETWEEN 1950 AND 1960
      AND p.p_channel_press = 'N'
      AND w.w_gmt_offset = -5.00
      AND ib.ib_upper_bound <= 50000
      AND ws.web_name LIKE '%Online%'
),
agg AS (
    SELECT
        d_year,
        s_store_id,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(sr_net_loss) AS total_returns_loss,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY d_year, s_store_id
)
SELECT
    s_store_id,
    AVG(total_sales) AS avg_sales,
    SUM(total_returns_loss) AS total_loss,
    SUM(txn_count) AS total_txns
FROM agg
GROUP BY s_store_id
HAVING AVG(total_sales) > 100000
ORDER BY avg_sales DESC
LIMIT 100
