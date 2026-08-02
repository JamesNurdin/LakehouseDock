WITH agg_store_sales AS (
    SELECT
        ss_store_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    GROUP BY ss_store_sk, ss_hdemo_sk, ss_addr_sk, ss_item_sk, ss_ticket_number
),

joined_data AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        cp.cp_catalog_page_id,
        cp.cp_description,
        ca_store.ca_city AS store_city,
        hd_store.hd_income_band_sk AS hd_store_income_band_sk,
        agg.total_net_paid,
        agg.total_quantity,
        sr.sr_return_amt,
        cr.cr_return_amount,
        wr.wr_return_amt,
        r.r_reason_desc,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        hd_web.hd_income_band_sk AS hd_web_income_band_sk,
        ca_web.ca_city AS web_city
    FROM agg_store_sales agg
    JOIN store s
        ON s.s_store_sk = agg.ss_store_sk
    JOIN household_demographics hd_store
        ON hd_store.hd_demo_sk = agg.ss_hdemo_sk
    JOIN customer_address ca_store
        ON ca_store.ca_address_sk = agg.ss_addr_sk
    FULL OUTER JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
           AND sr.sr_ticket_number = agg.ss_ticket_number
           AND sr.sr_item_sk = agg.ss_item_sk
    FULL OUTER JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_order_number = cr.cr_order_number
    JOIN catalog_page cp
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_web
        ON hd_web.hd_demo_sk = wr.wr_refunded_hdemo_sk
    JOIN customer_address ca_web
        ON ca_web.ca_address_sk = wr.wr_refunded_addr_sk
    WHERE EXISTS (
        SELECT 1 FROM store_returns sr_check
        WHERE sr_check.sr_store_sk = s.s_store_sk
    )
)

SELECT
    s_store_id,
    s_store_name,
    store_city,
    hd_store_income_band_sk,
    cp_catalog_page_id,
    cp_description,
    ship_mode_type,
    w_warehouse_name,
    r_reason_desc,
    SUM(total_net_paid) AS sum_total_net_paid,
    SUM(total_quantity) AS sum_total_quantity,
    SUM(COALESCE(sr_return_amt, 0)) AS sum_store_return_amount,
    SUM(COALESCE(cr_return_amount, 0)) AS sum_catalog_return_amount,
    SUM(COALESCE(wr_return_amt, 0)) AS sum_web_return_amount,
    (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) AS avg_catalog_sales_price
FROM joined_data
GROUP BY
    s_store_id,
    s_store_name,
    store_city,
    hd_store_income_band_sk,
    cp_catalog_page_id,
    cp_description,
    ship_mode_type,
    w_warehouse_name,
    r_reason_desc
ORDER BY sum_total_net_paid DESC
LIMIT 100
