WITH
    intersect_customers AS (
        SELECT sr_customer_sk
        FROM store_returns
        WHERE sr_return_amt > 1500
        INTERSECT
        SELECT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_ext_ship_cost > 1000
    ),
    joined_data AS (
        SELECT
            cd.cd_gender,
            cd.cd_marital_status,
            cd.cd_education_status,
            w.w_warehouse_name,
            sm.sm_type,
            wp.wp_type,
            ca.ca_state,
            r.r_reason_desc,
            sr.sr_return_amt,
            cs.cs_ext_sales_price,
            ws.ws_ext_ship_cost,
            ws.ws_ext_discount_amt,
            split(ca.ca_address_id, '') AS address_id_chars,
            sr.sr_customer_sk,
            CASE WHEN cs.cs_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
        FROM store_returns sr
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_customer_sk IN (SELECT sr_customer_sk FROM intersect_customers)
    ),
    aggregated AS (
        SELECT
            cd_gender,
            w_warehouse_name,
            profit_flag,
            SUM(sr_return_amt) AS sum_return,
            COUNT(*) AS rows_cnt,
            AVG(cs_ext_sales_price) AS avg_sales_price
        FROM joined_data
        GROUP BY cd_gender, w_warehouse_name, profit_flag
    ),
    full_reason_returns AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_return_amt,
            r.r_reason_desc
        FROM store_returns sr
        FULL OUTER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    ),
    cross_dim AS (
        SELECT cd_gender AS gender
        FROM (SELECT DISTINCT cd_gender FROM customer_demographics) g
        CROSS JOIN (SELECT 1 AS dummy) d
    )
SELECT
    a.cd_gender,
    a.w_warehouse_name,
    a.profit_flag,
    a.sum_return,
    a.rows_cnt,
    a.avg_sales_price,
    fr.r_reason_desc,
    c.address_char,
    ct.const_tag,
    cd_small.gender AS dim_gender
FROM aggregated a
LEFT JOIN full_reason_returns fr ON fr.r_reason_desc = a.profit_flag
LEFT JOIN (
        SELECT jd.cd_gender, elem AS address_char
        FROM joined_data jd
        CROSS JOIN UNNEST(jd.address_id_chars) AS t(elem)
    ) c ON c.cd_gender = a.cd_gender
CROSS JOIN (SELECT 'CONST' AS const_tag) ct
CROSS JOIN cross_dim cd_small
WHERE a.sum_return > 1000
ORDER BY a.sum_return DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
