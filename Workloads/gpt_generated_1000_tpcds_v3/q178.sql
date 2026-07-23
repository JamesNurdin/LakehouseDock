WITH
store_sales_returns_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_customer_sk AS cust_sk,
        ss.ss_cdemo_sk AS cd_demo_sk,
        ss.ss_hdemo_sk AS hd_demo_sk,
        ss.ss_addr_sk AS addr_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_customer_sk, ss.ss_cdemo_sk, ss.ss_hdemo_sk, ss.ss_addr_sk
),
catalog_sales_returns_agg AS (
    SELECT
        cs.cs_call_center_sk AS cc_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_bill_cdemo_sk AS cd_demo_sk,
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        cs.cs_bill_addr_sk AS addr_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY cs.cs_call_center_sk, cs.cs_sold_date_sk, cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk, cs.cs_bill_hdemo_sk, cs.cs_bill_addr_sk
),
web_sales_returns_agg AS (
    SELECT
        ws.ws_web_page_sk AS wp_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_bill_cdemo_sk AS cd_demo_sk,
        ws.ws_bill_hdemo_sk AS hd_demo_sk,
        ws.ws_bill_addr_sk AS addr_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    GROUP BY ws.ws_web_page_sk, ws.ws_sold_date_sk, ws.ws_bill_customer_sk, ws.ws_bill_cdemo_sk, ws.ws_bill_hdemo_sk, ws.ws_bill_addr_sk
),
combined_sales AS (
    SELECT
        'store'   AS src,
        ss.store_sk AS entity_id,
        ss.sold_date_sk AS date_sk,
        ss.cust_sk,
        ss.cd_demo_sk,
        ss.hd_demo_sk,
        ss.addr_sk,
        ss.total_sales,
        ss.total_profit,
        ss.sales_cnt,
        ss.total_return_loss
    FROM store_sales_returns_agg ss
    UNION ALL
    SELECT
        'catalog' AS src,
        cs.cc_sk   AS entity_id,
        cs.sold_date_sk AS date_sk,
        cs.cust_sk,
        cs.cd_demo_sk,
        cs.hd_demo_sk,
        cs.addr_sk,
        cs.total_sales,
        cs.total_profit,
        cs.sales_cnt,
        cs.total_return_loss
    FROM catalog_sales_returns_agg cs
    UNION ALL
    SELECT
        'web'    AS src,
        ws.wp_sk AS entity_id,
        ws.sold_date_sk AS date_sk,
        ws.cust_sk,
        ws.cd_demo_sk,
        ws.hd_demo_sk,
        ws.addr_sk,
        ws.total_sales,
        ws.total_profit,
        ws.sales_cnt,
        ws.total_return_loss
    FROM web_sales_returns_agg ws
)
SELECT
    cs.src,
    d.d_year,
    SUM(cs.total_sales) AS year_total_sales,
    SUM(cs.total_profit) AS year_total_profit,
    SUM(cs.total_return_loss) AS year_total_return_loss,
    CASE WHEN SUM(cs.total_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_status,
    SUM(cs.total_sales) / (SELECT AVG(total_sales) FROM combined_sales) AS sales_vs_avg,
    COUNT(DISTINCT cs.cust_sk) AS distinct_customers,
    MAX(ib.ib_upper_bound) AS max_income_upper_bound
FROM combined_sales cs
JOIN date_dim d
    ON cs.date_sk = d.d_date_sk
LEFT JOIN store s
    ON cs.src = 'store' AND cs.entity_id = s.s_store_sk
LEFT JOIN call_center cc
    ON cs.src = 'catalog' AND cs.entity_id = cc.cc_call_center_sk
LEFT JOIN web_page wp
    ON cs.src = 'web' AND cs.entity_id = wp.wp_web_page_sk
LEFT JOIN customer c
    ON cs.cust_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON cs.addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON cs.cd_demo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON cs.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year = 2000
  AND (s.s_state = 'CA' OR s.s_state IS NULL)
  AND (cc.cc_class = 'A' OR cc.cc_class IS NULL)
  AND hd.hd_buy_potential = '>10000'
  AND ib.ib_upper_bound > 50000
  AND (wp.wp_type = 'Content' OR wp.wp_type IS NULL)
GROUP BY cs.src, d.d_year
HAVING SUM(cs.total_sales) > 1000000
ORDER BY year_total_sales DESC
LIMIT 100
