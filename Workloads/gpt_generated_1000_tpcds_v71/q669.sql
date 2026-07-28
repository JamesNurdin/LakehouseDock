WITH
    store_agg AS (
        SELECT
            ss_store_sk,
            ss_item_sk,
            ss_hdemo_sk,
            ss_addr_sk,
            SUM(ss_ext_sales_price) AS store_sales_total,
            COUNT(*) AS store_sales_cnt
        FROM store_sales
        WHERE ss_quantity > 1
        GROUP BY ss_store_sk, ss_item_sk, ss_hdemo_sk, ss_addr_sk
    ),
    web_agg AS (
        SELECT
            NULL AS ss_store_sk,
            ws_item_sk AS ss_item_sk,
            ws_bill_hdemo_sk AS ss_hdemo_sk,
            ws_bill_addr_sk AS ss_addr_sk,
            SUM(ws_ext_sales_price) AS web_sales_total,
            COUNT(*) AS web_sales_cnt
        FROM web_sales
        WHERE ws_quantity > 1
        GROUP BY ws_item_sk, ws_bill_hdemo_sk, ws_bill_addr_sk
    ),
    combined AS (
        SELECT
            ss_store_sk,
            ss_item_sk,
            ss_hdemo_sk,
            ss_addr_sk,
            store_sales_total AS sales_total,
            store_sales_cnt AS sales_cnt,
            'store' AS channel
        FROM store_agg
        UNION ALL
        SELECT
            ss_store_sk,
            ss_item_sk,
            ss_hdemo_sk,
            ss_addr_sk,
            web_sales_total AS sales_total,
            web_sales_cnt AS sales_cnt,
            'web' AS channel
        FROM web_agg
    ),
    catalog_agg AS (
        SELECT
            cs_item_sk,
            cs_bill_hdemo_sk,
            cs_bill_addr_sk,
            SUM(cs_ext_sales_price) AS catalog_sales_total,
            COUNT(*) AS catalog_sales_cnt,
            SUM(cs_net_paid_inc_tax) AS catalog_net_paid_inc_tax
        FROM catalog_sales
        WHERE cs_quantity > 1
        GROUP BY cs_item_sk, cs_bill_hdemo_sk, cs_bill_addr_sk
    )
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_class,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ca.ca_state,
    s.s_store_name,
    combined.channel,
    SUM(combined.sales_total) AS total_sales,
    SUM(combined.sales_cnt) AS total_transactions,
    SUM(ca_agg.catalog_sales_total) AS catalog_total_sales,
    SUM(ca_agg.catalog_sales_cnt) AS catalog_transactions,
    AVG(ca_agg.catalog_net_paid_inc_tax) AS avg_catalog_net_paid_inc_tax
FROM combined
JOIN item i ON combined.ss_item_sk = i.i_item_sk
JOIN household_demographics hd ON combined.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON combined.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store s ON combined.ss_store_sk = s.s_store_sk
JOIN catalog_agg ca_agg ON combined.ss_item_sk = ca_agg.cs_item_sk
    AND combined.ss_hdemo_sk = ca_agg.cs_bill_hdemo_sk
    AND combined.ss_addr_sk = ca_agg.cs_bill_addr_sk
WHERE
    i.i_class_id = 7
    AND i.i_brand_id = 6008007
    AND hd.hd_dep_count >= 5
    AND ib.ib_lower_bound >= 20000
    AND ca.ca_state = 'TX'
    AND (combined.channel = 'web' OR s.s_state = 'WA')
GROUP BY
    i.i_item_id,
    i.i_brand,
    i.i_class,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ca.ca_state,
    s.s_store_name,
    combined.channel
ORDER BY total_sales DESC
LIMIT 100
