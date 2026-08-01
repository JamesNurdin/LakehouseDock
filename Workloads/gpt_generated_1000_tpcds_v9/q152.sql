WITH base AS (
    SELECT 
        s.s_store_name,
        cc.cc_name,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        c.c_customer_id,
        ss.ss_net_profit,
        cs.cs_net_paid,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        cr.cr_return_amount,
        cs.cs_ext_sales_price,
        ss.ss_ticket_number,
        sr.sr_reason_sk,
        cs.cs_sold_date_sk,
        wp.wp_type,
        r_store.r_reason_desc AS store_return_reason,
        r_catalog.r_reason_desc AS catalog_return_reason,
        r_web.r_reason_desc AS web_return_reason,
        ss.ss_store_sk AS store_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r_catalog ON cr.cr_reason_sk = r_catalog.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
    WHERE 
        cc.cc_state = 'NY'
        AND cd.cd_marital_status = 'M'
        AND ib.ib_lower_bound >= 60000
        AND cc.cc_rec_start_date >= DATE '2001-01-01'
        AND sr.sr_reason_sk IN (
            SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%Damaged%'
        )
)
SELECT 
    s_store_name,
    cc_name,
    cd_marital_status,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(sr_net_loss) AS total_store_returns_loss,
    SUM(cr_net_loss) AS total_catalog_returns_loss,
    SUM(wr_net_loss) AS total_web_returns_loss,
    AVG(cs_ext_sales_price) AS avg_catalog_ext_sales_price,
    SUM(CASE WHEN cr_return_amount > 100 THEN cr_return_amount ELSE 0 END) AS high_value_catalog_returns,
    CASE 
        WHEN SUM(ss_net_profit) > 0 THEN 'Profit' 
        ELSE 'Loss' 
    END AS overall_profit_status,
    (SELECT AVG(ss2.ss_net_profit)
       FROM store_sales ss2
       WHERE ss2.ss_store_sk = store_sk) AS avg_store_profit
FROM base
GROUP BY 
    s_store_name,
    cc_name,
    cd_marital_status,
    ib_lower_bound,
    ib_upper_bound,
    store_sk
ORDER BY 
    total_store_profit DESC,
    distinct_customers DESC
LIMIT 100
