WITH store_agg AS (
    SELECT ss_hdemo_sk,
           SUM(ss_ext_sales_price) AS store_sales_total,
           SUM(ss_ext_discount_amt) AS store_discount_total,
           COUNT(*)               AS store_txn_cnt
    FROM store_sales
    WHERE ss_ext_sales_price > 1000            -- filter 1
      AND ss_quantity >= 2                     -- filter 2
    GROUP BY ss_hdemo_sk
)
SELECT
    hd_s.hd_demo_sk,
    hd_s.hd_income_band_sk,
    hd_s.hd_vehicle_count,
    s.store_sales_total,
    s.store_discount_total,
    s.store_txn_cnt,
    w.w_warehouse_name,
    wp.wp_url,
    p.p_promo_name,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ROW_NUMBER() OVER (PARTITION BY hd_s.hd_demo_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn_sales_desc,
    RANK()       OVER (ORDER BY s.store_sales_total DESC)               AS store_sales_rank,
    CASE
        WHEN hd_s.hd_vehicle_count > 2 THEN 'HighVehicle'
        WHEN hd_s.hd_vehicle_count = 0 THEN 'NoVehicle'
        ELSE 'Other'
    END AS vehicle_category
FROM store_agg s
JOIN household_demographics hd_s
     ON s.ss_hdemo_sk = hd_s.hd_demo_sk
JOIN web_sales ws
     ON ws.ws_bill_hdemo_sk = hd_s.hd_demo_sk
JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
WHERE w.w_state = 'CA'                               -- filter 3
  AND wp.wp_type = 'content'                         -- filter 4
  AND p.p_discount_active = 'Y'                      -- filter 5
  AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915 -- filter 6 (date surrogate key range)
ORDER BY s.store_sales_total DESC
LIMIT 100
