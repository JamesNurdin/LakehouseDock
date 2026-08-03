WITH
    sampled_item AS (
        SELECT *
        FROM item
        TABLESAMPLE BERNOULLI (10)
    ),
    agg_store_sales AS (
        SELECT
            ss_item_sk,
            ss_customer_sk,
            ss_sold_date_sk,
            SUM(ss_ext_sales_price) AS store_sales_total,
            SUM(ss_quantity) AS store_quantity_total
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2452000 AND 2453000
        GROUP BY ss_item_sk, ss_customer_sk, ss_sold_date_sk
    ),
    agg_web_sales AS (
        SELECT
            ws_item_sk,
            ws_bill_customer_sk AS web_customer_sk,
            ws_sold_date_sk,
            SUM(ws_ext_sales_price) AS web_sales_total,
            SUM(ws_quantity) AS web_quantity_total
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2452000 AND 2453000
        GROUP BY ws_item_sk, ws_bill_customer_sk, ws_sold_date_sk
    ),
    combined_sales AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_customer_sk,
            ss.ss_sold_date_sk,
            wr.ws_item_sk,
            wr.web_customer_sk,
            wr.ws_sold_date_sk,
            ss.store_sales_total,
            ss.store_quantity_total,
            wr.web_sales_total,
            wr.web_quantity_total
        FROM agg_store_sales ss
        FULL OUTER JOIN agg_web_sales wr
            ON ss.ss_item_sk = wr.ws_item_sk
           AND ss.ss_customer_sk = wr.web_customer_sk
           AND ss.ss_sold_date_sk = wr.ws_sold_date_sk
    ),
    order_diff AS (
        SELECT ss_ticket_number AS order_key
        FROM store_sales
        EXCEPT
        SELECT ws_order_number AS order_key
        FROM web_sales
    ),
    final_set AS (
        SELECT *
        FROM combined_sales
        WHERE store_sales_total IS NOT NULL OR web_sales_total IS NOT NULL
    )
SELECT
    ca.ca_state,
    i.i_category,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    sm.sm_carrier,
    SUM(COALESCE(f.store_sales_total, 0) + COALESCE(f.web_sales_total, 0)) AS total_sales,
    COUNT(DISTINCT COALESCE(f.ss_item_sk, f.ws_item_sk)) AS distinct_items_sold,
    AVG(COALESCE(f.store_quantity_total, 0) + COALESCE(f.web_quantity_total, 0)) AS avg_quantity,
    MIN(COALESCE(f.store_sales_total, 0) + COALESCE(f.web_sales_total, 0)) AS min_sales,
    MAX(COALESCE(f.store_sales_total, 0) + COALESCE(f.web_sales_total, 0)) AS max_sales
FROM final_set f
JOIN sampled_item i
    ON i.i_item_sk = COALESCE(f.ss_item_sk, f.ws_item_sk)
JOIN customer c
    ON c.c_customer_sk = COALESCE(f.ss_customer_sk, f.web_customer_sk)
JOIN customer_address ca
    ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = (
        SELECT sm_ship_mode_sk
        FROM ship_mode
        WHERE sm_carrier = 'DIAMOND'
        LIMIT 1
    )
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN time_dim td
    ON td.t_time_sk = COALESCE(sr.sr_return_time_sk, wr.wr_returned_time_sk)
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) AS cross_dummy
CROSS JOIN order_diff od
WHERE cd.cd_gender = 'F'
  AND cd.cd_education_status = 'Advanced Degree'
  AND cd.cd_dep_employed_count > 2
  AND ca.ca_country = 'United States'
  AND sm.sm_type = 'AIR'
  AND ib.ib_upper_bound > 50000
  AND i.i_brand = 'Brand#12'
  AND td.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = sr.sr_reason_sk
          AND r.r_reason_desc LIKE '%defect%'
    )
GROUP BY ca.ca_state, i.i_category, hd.hd_buy_potential, ib.ib_lower_bound, sm.sm_carrier
HAVING SUM(COALESCE(f.store_sales_total, 0) + COALESCE(f.web_sales_total, 0)) > 100000
ORDER BY total_sales DESC
LIMIT 100
