WITH
joined_data AS (
    SELECT
        cp.cp_type,
        cp.cp_catalog_number,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_order_number,
        cs.cs_quantity,
        ss.ss_list_price,
        ss.ss_quantity,
        ss.ss_customer_sk,
        ws.ws_net_paid,
        ws.ws_order_number,
        cd.cd_gender,
        cd.cd_education_status,
        cs.cs_bill_cdemo_sk,
        s_agg.total_store_qty
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT sum(ss2.ss_quantity) AS total_store_qty
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = ss.ss_customer_sk
    ) s_agg
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_catalog_number IN (1, 9, 14)
      AND cs.cs_net_paid_inc_ship_tax > 1000
      AND ss.ss_list_price BETWEEN 50 AND 80
      AND cd.cd_gender = 'F'
      AND ws.ws_net_paid > 2000
),
exclusive_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 1000
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_net_paid > 2000
),
agg_data AS (
    SELECT
        jd.cp_type,
        jd.cd_gender,
        jd.cp_catalog_number,
        sum(jd.cs_net_paid_inc_ship_tax) AS total_net_paid,
        sum(jd.ws_net_paid)          AS total_ws_paid,
        avg(jd.cs_quantity)          AS avg_cs_quantity,
        count(*)                     AS records_cnt,
        max(CASE WHEN jd.cs_order_number IN (SELECT cs_order_number FROM exclusive_orders) THEN 1 ELSE 0 END) AS has_exclusive_order
    FROM joined_data jd
    GROUP BY ROLLUP (jd.cp_type, jd.cd_gender, jd.cp_catalog_number)
    HAVING sum(jd.cs_net_paid_inc_ship_tax) > 5000
)
SELECT
    cp_type,
    cd_gender,
    cp_catalog_number,
    total_net_paid,
    total_ws_paid,
    avg_cs_quantity,
    records_cnt,
    has_exclusive_order
FROM agg_data
ORDER BY total_net_paid DESC
LIMIT 100
