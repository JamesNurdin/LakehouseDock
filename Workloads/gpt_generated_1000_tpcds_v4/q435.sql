WITH distinct_demo AS (
    SELECT DISTINCT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
    WHERE cd_marital_status IN ('M', 'S')
      AND cd_gender = 'F'
      AND cd_dep_employed_count >= 2
      AND cd_dep_college_count <= 4
),
agg_store AS (
    SELECT
        ss_cdemo_sk,
        COUNT(*) AS store_txn_cnt,
        SUM(ss_net_paid) AS store_net_paid,
        AVG(ss_quantity) AS avg_quantity
    FROM store_sales
    WHERE ss_quantity > 1
      AND ss_net_paid > 0
      AND ss_sold_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY ss_cdemo_sk
),
agg_catalog AS (
    SELECT
        cs_bill_cdemo_sk,
        COUNT(DISTINCT cs_order_number) AS catalog_orders,
        SUM(cs_ext_sales_price) AS catalog_sales_amt,
        AVG(cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales
    WHERE cs_ext_discount_amt > 10.00
      AND cs_ship_cdemo_sk = 1569035
      AND cs_list_price BETWEEN 20 AND 500
    GROUP BY cs_bill_cdemo_sk
),
agg_web AS (
    SELECT
        wr_refunded_cdemo_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        MAX(wr_return_ship_cost) AS max_ship_cost
    FROM web_returns
    WHERE wr_return_amt > 100.00
      AND wr_return_ship_cost < 500.00
      AND wr_reversed_charge BETWEEN 20.00 AND 400.00
    GROUP BY wr_refunded_cdemo_sk
)
SELECT
    d.cd_gender,
    d.cd_marital_status,
    d.cd_dep_employed_count,
    d.cd_dep_college_count,
    s.store_txn_cnt,
    s.store_net_paid,
    s.avg_quantity,
    c.catalog_orders,
    c.catalog_sales_amt,
    c.avg_discount,
    w.web_return_cnt,
    w.total_return_amt,
    w.max_ship_cost
FROM distinct_demo d
LEFT JOIN agg_store s
    ON s.ss_cdemo_sk = d.cd_demo_sk
LEFT JOIN agg_catalog c
    ON c.cs_bill_cdemo_sk = d.cd_demo_sk
LEFT JOIN agg_web w
    ON w.wr_refunded_cdemo_sk = d.cd_demo_sk
ORDER BY d.cd_gender,
         d.cd_marital_status,
         d.cd_dep_employed_count DESC
