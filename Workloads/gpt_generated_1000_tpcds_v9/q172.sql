/*
  Goal: Summarize sales and returns across store, catalog, and web channels per item and store,
        calculate total sales, total returns, net sales and profit, label profit status,
        rank items by sales volume, count distinct customers and return reasons, and filter
        to recent items sold in California stores managed by the 'anti' division.
*/
WITH
    ss_agg AS (
        SELECT
            ss_item_sk,
            ss_store_sk,
            ss_customer_sk,
            ss_addr_sk,
            ss_promo_sk,
            SUM(ss_ext_sales_price) AS store_sales_total,
            SUM(ss_net_profit)      AS store_profit
        FROM store_sales
        GROUP BY ss_item_sk, ss_store_sk, ss_customer_sk, ss_addr_sk, ss_promo_sk
    ),
    cs_agg AS (
        SELECT
            cs_item_sk,
            cs_call_center_sk,
            cs_ship_mode_sk,
            cs_promo_sk,
            cs_bill_customer_sk,
            cs_bill_addr_sk,
            SUM(cs_ext_sales_price) AS catalog_sales_total,
            SUM(cs_net_profit)      AS catalog_profit
        FROM catalog_sales
        GROUP BY cs_item_sk, cs_call_center_sk, cs_ship_mode_sk, cs_promo_sk, cs_bill_customer_sk, cs_bill_addr_sk
    ),
    ws_agg AS (
        SELECT
            ws_item_sk,
            ws_ship_mode_sk,
            ws_promo_sk,
            ws_bill_customer_sk,
            ws_bill_addr_sk,
            SUM(ws_ext_sales_price) AS web_sales_total,
            SUM(ws_net_profit)      AS web_profit
        FROM web_sales
        GROUP BY ws_item_sk, ws_ship_mode_sk, ws_promo_sk, ws_bill_customer_sk, ws_bill_addr_sk
    ),
    sr_agg AS (
        SELECT
            sr_item_sk,
            sr_store_sk,
            sr_reason_sk,
            SUM(sr_return_amt)  AS store_returns_total,
            SUM(sr_net_loss)    AS store_returns_loss
        FROM store_returns
        GROUP BY sr_item_sk, sr_store_sk, sr_reason_sk
    ),
    cr_agg AS (
        SELECT
            cr_item_sk,
            cr_reason_sk,
            SUM(cr_return_amount) AS catalog_returns_total,
            SUM(cr_net_loss)      AS catalog_returns_loss
        FROM catalog_returns
        GROUP BY cr_item_sk, cr_reason_sk
    )
SELECT DISTINCT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    s.s_store_id,
    s.s_store_name,
    cc.cc_division_name,
    sm_cs.sm_code AS catalog_ship_mode,
    sm_ws.sm_code AS web_ship_mode,
    p_ss.p_promo_name AS store_promo,
    p_cs.p_promo_name AS catalog_promo,
    p_ws.p_promo_name AS web_promo,
    COALESCE(ss_agg.store_sales_total, 0) +
    COALESCE(cs_agg.catalog_sales_total, 0) +
    COALESCE(ws_agg.web_sales_total, 0) AS total_sales_amount,
    COALESCE(sr_agg.store_returns_total, 0) +
    COALESCE(cr_agg.catalog_returns_total, 0) AS total_returns_amount,
    (COALESCE(ss_agg.store_sales_total, 0) +
     COALESCE(cs_agg.catalog_sales_total, 0) +
     COALESCE(ws_agg.web_sales_total, 0)) -
    (COALESCE(sr_agg.store_returns_total, 0) +
     COALESCE(cr_agg.catalog_returns_total, 0)) AS net_sales_amount,
    COALESCE(ss_agg.store_profit, 0) +
    COALESCE(cs_agg.catalog_profit, 0) +
    COALESCE(ws_agg.web_profit, 0) -
    COALESCE(sr_agg.store_returns_loss, 0) -
    COALESCE(cr_agg.catalog_returns_loss, 0) AS total_profit,
    CASE WHEN (COALESCE(ss_agg.store_profit, 0) +
               COALESCE(cs_agg.catalog_profit, 0) +
               COALESCE(ws_agg.web_profit, 0) -
               COALESCE(sr_agg.store_returns_loss, 0) -
               COALESCE(cr_agg.catalog_returns_loss, 0)) > 0
         THEN 'Profit'
         ELSE 'Loss'
    END AS profit_flag,
    COUNT(DISTINCT c_ss.c_customer_id) AS distinct_customer_count,
    COUNT(DISTINCT r.r_reason_desc)   AS distinct_store_return_reasons,
    COUNT(DISTINCT r2.r_reason_desc)  AS distinct_catalog_return_reasons,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(ss_agg.store_sales_total, 0) +
                                 COALESCE(cs_agg.catalog_sales_total, 0) +
                                 COALESCE(ws_agg.web_sales_total, 0)) DESC) AS sales_rank,
    DENSE_RANK() OVER (PARTITION BY i.i_category ORDER BY (COALESCE(ss_agg.store_sales_total, 0) +
                                                             COALESCE(cs_agg.catalog_sales_total, 0) +
                                                             COALESCE(ws_agg.web_sales_total, 0)) DESC) AS category_rank
FROM item i
LEFT JOIN ss_agg ON i.i_item_sk = ss_agg.ss_item_sk
LEFT JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p_ss ON ss_agg.ss_promo_sk = p_ss.p_promo_sk
LEFT JOIN customer c_ss ON ss_agg.ss_customer_sk = c_ss.c_customer_sk
LEFT JOIN customer_address ca_ss ON ss_agg.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN cs_agg ON i.i_item_sk = cs_agg.cs_item_sk
LEFT JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm_cs ON cs_agg.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
LEFT JOIN promotion p_cs ON cs_agg.cs_promo_sk = p_cs.p_promo_sk
LEFT JOIN customer c_cs ON cs_agg.cs_bill_customer_sk = c_cs.c_customer_sk
LEFT JOIN customer_address ca_cs ON cs_agg.cs_bill_addr_sk = ca_cs.ca_address_sk
LEFT JOIN ws_agg ON i.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN ship_mode sm_ws ON ws_agg.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN promotion p_ws ON ws_agg.ws_promo_sk = p_ws.p_promo_sk
LEFT JOIN customer c_ws ON ws_agg.ws_bill_customer_sk = c_ws.c_customer_sk
LEFT JOIN customer_address ca_ws ON ws_agg.ws_bill_addr_sk = ca_ws.ca_address_sk
LEFT JOIN sr_agg ON i.i_item_sk = sr_agg.sr_item_sk AND s.s_store_sk = sr_agg.sr_store_sk
LEFT JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
LEFT JOIN cr_agg ON i.i_item_sk = cr_agg.cr_item_sk
LEFT JOIN reason r2 ON cr_agg.cr_reason_sk = r2.r_reason_sk
WHERE i.i_rec_start_date >= DATE '2001-01-01'
  AND i.i_rec_end_date   <= DATE '2002-12-31'
  AND s.s_state = 'CA'
  AND cc.cc_division_name = 'anti'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    s.s_store_id,
    s.s_store_name,
    cc.cc_division_name,
    sm_cs.sm_code,
    sm_ws.sm_code,
    p_ss.p_promo_name,
    p_cs.p_promo_name,
    p_ws.p_promo_name,
    ss_agg.store_sales_total,
    cs_agg.catalog_sales_total,
    ws_agg.web_sales_total,
    sr_agg.store_returns_total,
    cr_agg.catalog_returns_total,
    ss_agg.store_profit,
    cs_agg.catalog_profit,
    ws_agg.web_profit,
    sr_agg.store_returns_loss,
    cr_agg.catalog_returns_loss
HAVING (COALESCE(ss_agg.store_sales_total, 0) +
         COALESCE(cs_agg.catalog_sales_total, 0) +
         COALESCE(ws_agg.web_sales_total, 0)) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100
