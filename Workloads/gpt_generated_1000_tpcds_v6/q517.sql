WITH filtered AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_ext_tax,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        sr.sr_return_tax,
        sr.sr_refunded_cash,
        sr.sr_return_amt,
        sm.sm_type
    FROM tpcds.customer_demographics cd
    JOIN tpcds.catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    WHERE cd.cd_marital_status = 'M'
      AND cd.cd_dep_employed_count >= 2
      AND cs.cs_sales_price > 20
      AND cs.cs_ext_tax < 50
      AND sr.sr_return_tax > 1
      AND ws.ws_quantity >= 2
      AND sm.sm_type = 'AIR'
)
SELECT
    cd_gender,
    cd_marital_status,
    sm_type,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    SUM(sr_refunded_cash) AS total_refunded_cash,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    MAX(sr_return_amt) AS max_return_amount,
    MIN(ws_quantity) AS min_web_quantity
FROM filtered
GROUP BY cd_gender, cd_marital_status, sm_type
ORDER BY total_catalog_net_paid DESC
LIMIT 100
