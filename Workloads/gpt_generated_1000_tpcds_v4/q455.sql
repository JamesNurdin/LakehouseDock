WITH base AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        d.d_quarter_seq,
        d.d_year,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_net_paid_inc_tax AS cs_net_paid_inc_tax,
        ss.ss_sales_price AS ss_sales_price,
        hd.hd_vehicle_count AS hd_vehicle_count,
        cs.cs_bill_customer_sk AS cs_bill_customer_sk,
        ss.ss_customer_sk AS ss_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq IN (3, 9, 15)
      AND cs.cs_net_paid_inc_tax > 1000
      AND ss.ss_sales_price BETWEEN 10 AND 100
      AND hd.hd_vehicle_count >= 1
      AND w.w_warehouse_sq_ft > 50000
),
agg AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        d_quarter_seq,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT cs_bill_customer_sk) AS distinct_bill_customers,
        COUNT(DISTINCT ss_customer_sk) AS distinct_store_customers
    FROM base
    GROUP BY w_warehouse_sk, w_warehouse_name, d_quarter_seq
)
SELECT
    w_warehouse_name,
    AVG(total_catalog_profit + total_store_profit) AS avg_total_profit,
    SUM(distinct_bill_customers) AS total_bill_customers,
    SUM(distinct_store_customers) AS total_store_customers
FROM agg
WHERE (total_catalog_profit + total_store_profit) > 5000
GROUP BY w_warehouse_name
ORDER BY avg_total_profit DESC
LIMIT 100
