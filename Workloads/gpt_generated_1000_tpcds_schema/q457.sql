WITH
    -- Sample a fraction of customer_address for later join
    sampled_ca AS (
        SELECT *
        FROM customer_address
        TABLESAMPLE BERNOULLI (10)
        WHERE ca_state = 'CA' AND ca_street_type = 'ST'
    ),
    -- Aggregate store sales by item, promotion, address and customer (pre‑aggregation)
    store_agg AS (
        SELECT
            ss_item_sk      AS item_sk,
            ss_promo_sk     AS promo_sk,
            ss_addr_sk      AS addr_sk,
            ss_customer_sk  AS customer_sk,
            ss_hdemo_sk     AS hdemo_sk,
            SUM(ss_ext_sales_price) AS store_sales_total,
            SUM(ss_quantity)       AS store_quantity,
            COUNT(*)               AS store_txn_cnt
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450500
          AND ss_quantity > 1
        GROUP BY ss_item_sk, ss_promo_sk, ss_addr_sk, ss_customer_sk, ss_hdemo_sk
    ),
    -- Aggregate web sales by the same keys and keep extra columns for later joins
    web_agg AS (
        SELECT
            ws_item_sk          AS item_sk,
            ws_promo_sk         AS promo_sk,
            ws_bill_addr_sk     AS addr_sk,
            ws_bill_customer_sk AS customer_sk,
            ws_bill_hdemo_sk    AS hdemo_sk,
            ws_web_page_sk      AS web_page_sk,
            ws_web_site_sk      AS web_site_sk,
            ws_order_number     AS order_number,
            SUM(ws_ext_sales_price) AS web_sales_total,
            SUM(ws_quantity)        AS web_quantity,
            COUNT(*)                AS web_txn_cnt
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450500
          AND ws_quantity > 1
        GROUP BY ws_item_sk, ws_promo_sk, ws_bill_addr_sk, ws_bill_customer_sk,
                 ws_bill_hdemo_sk, ws_web_page_sk, ws_web_site_sk, ws_order_number
    ),
    -- Full outer join the two aggregates, keeping rows that exist in only one side
    full_sales AS (
        SELECT
            COALESCE(s.item_sk, w.item_sk)           AS item_sk,
            COALESCE(s.promo_sk, w.promo_sk)         AS promo_sk,
            COALESCE(s.addr_sk, w.addr_sk)           AS addr_sk,
            COALESCE(s.customer_sk, w.customer_sk)   AS customer_sk,
            COALESCE(s.hdemo_sk, w.hdemo_sk)         AS hdemo_sk,
            s.store_sales_total,
            w.web_sales_total,
            s.store_quantity,
            w.web_quantity,
            s.store_txn_cnt,
            w.web_txn_cnt,
            w.web_page_sk,
            w.web_site_sk,
            w.order_number
        FROM store_agg s
        FULL OUTER JOIN web_agg w
            ON s.item_sk = w.item_sk
           AND s.promo_sk = w.promo_sk
           AND s.addr_sk = w.addr_sk
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY
        COALESCE(fs.store_sales_total, 0) + COALESCE(fs.web_sales_total, 0) DESC) AS row_num,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    COALESCE(fs.store_sales_total, 0) AS store_sales_total,
    COALESCE(fs.web_sales_total, 0)   AS web_sales_total,
    COALESCE(fs.store_quantity, 0)    AS store_quantity,
    COALESCE(fs.web_quantity, 0)      AS web_quantity,
    COALESCE(fs.store_txn_cnt, 0)     AS store_txn_cnt,
    COALESCE(fs.web_txn_cnt, 0)       AS web_txn_cnt,
    ca.ca_city,
    ca.ca_state,
    hd.hd_income_band_sk,
    wp.wp_type,
    ws.web_site_sk,
    fs.order_number
FROM full_sales fs
JOIN item i
    ON i.i_item_sk = fs.item_sk
JOIN promotion p
    ON p.p_promo_sk = fs.promo_sk
JOIN sampled_ca ca
    ON ca.ca_address_sk = fs.addr_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = fs.hdemo_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = fs.web_page_sk
JOIN web_site ws
    ON ws.web_site_sk = fs.web_site_sk
JOIN web_returns wr
    ON wr.wr_order_number = fs.order_number
WHERE p.p_channel_radio = 'N'
  AND i.i_current_price > 100
  AND p.p_purpose = 'Unknown'
  AND hd.hd_vehicle_count > 1
  AND ws.web_state = 'CA'
ORDER BY store_sales_total DESC NULLS LAST
LIMIT 100
