WITH joined_data AS (
    SELECT
        s.s_store_name AS s_store_name,
        cp.cp_department AS cp_department,
        sm.sm_ship_mode_id AS sm_ship_mode_id,
        cd.cd_gender AS cd_gender,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid_inc_tax AS ss_net_paid_inc_tax,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_ext_list_price AS ws_ext_list_price,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_return_quantity AS wr_return_quantity
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE
        s.s_state = 'CA'
        AND cp.cp_department = 'Electronics'
        AND sm.sm_carrier = 'UPS'
        AND cd.cd_gender = 'M'
        AND ss.ss_quantity > 5
        AND cs.cs_ext_sales_price > 500
        AND ws.ws_ext_list_price > 2000
        AND wr.wr_return_quantity > 0
        AND ss.ss_net_paid_inc_tax BETWEEN 1000 AND 5000
)
SELECT
    s_store_name,
    cp_department,
    sm_ship_mode_id,
    cd_gender,
    COUNT(*) AS order_count,
    SUM(ss_net_paid_inc_tax) AS total_store_sales,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(wr_return_amt) AS total_returns_amount,
    AVG(ss_net_paid_inc_tax) AS avg_store_sales_per_order,
    MIN(ss_net_paid_inc_tax) AS min_store_sales,
    MAX(ss_net_paid_inc_tax) AS max_store_sales
FROM joined_data
GROUP BY
    s_store_name,
    cp_department,
    sm_ship_mode_id,
    cd_gender
ORDER BY total_store_sales DESC
LIMIT 100
