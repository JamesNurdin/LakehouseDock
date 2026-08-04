WITH
catalog_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_warehouse_sk,
        cs.cs_list_price,
        cs.cs_net_profit,
        d_sold.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_customer_sk = cust.c_customer_sk
    WHERE cs.cs_list_price > (SELECT avg(cs_list_price) FROM catalog_sales)
),
store_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        d_ss.d_year,
        cd2.cd_gender,
        hd2.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer cust2 ON ss.ss_customer_sk = cust2.c_customer_sk
    JOIN customer_demographics cd2 ON ss.ss_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
),
catalog_customers AS (
    SELECT DISTINCT cs_bill_customer_sk AS c_customer_sk
    FROM catalog_sales
),
store_customers AS (
    SELECT DISTINCT ss_customer_sk AS c_customer_sk
    FROM store_sales
),
catalog_only_customers AS (
    SELECT c_customer_sk
    FROM catalog_customers
    EXCEPT
    SELECT c_customer_sk
    FROM store_customers
)
SELECT
    d_year,
    cd_gender,
    SUM(total_catalog_profit) AS catalog_profit,
    SUM(total_store_profit) AS store_profit,
    COUNT(DISTINCT c_customer_sk) AS num_customers
FROM (
    SELECT
        cb.d_year,
        cb.cd_gender,
        cb.cs_net_profit AS total_catalog_profit,
        0.0 AS total_store_profit,
        cb.cs_bill_customer_sk AS c_customer_sk
    FROM catalog_base cb
    WHERE cb.cs_bill_customer_sk IN (SELECT c_customer_sk FROM catalog_only_customers)
    UNION ALL
    SELECT
        sb.d_year,
        sb.cd_gender,
        0.0 AS total_catalog_profit,
        sb.ss_net_profit AS total_store_profit,
        sb.ss_customer_sk AS c_customer_sk
    FROM store_base sb
) AS combined
GROUP BY d_year, cd_gender
ORDER BY d_year DESC, catalog_profit DESC
LIMIT 100
