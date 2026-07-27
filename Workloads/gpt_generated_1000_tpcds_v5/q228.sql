WITH catalog_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        cp.cp_department,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MAX(cs.cs_ext_sales_price) AS max_ext_sales_price
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cp.cp_end_date_sk BETWEEN 2450800 AND 2451500
      AND c.c_birth_country IN ('KOREA','FIJI','SLOVENIA')
      AND cs.cs_wholesale_cost > 20
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        cp.cp_department
)
SELECT
    ca.c_customer_id,
    ca.c_birth_country,
    ca.cp_department,
    COALESCE(ss.ss_ext_sales_price, 0) AS store_sales_amount,
    CASE
        WHEN ca.total_catalog_profit > 15000 THEN 'HIGH'
        WHEN ca.total_catalog_profit > 8000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ca.total_catalog_profit,
    ROW_NUMBER() OVER (PARTITION BY ca.c_birth_country ORDER BY ca.total_catalog_profit DESC) AS profit_rank_by_country,
    (SELECT COUNT(*)
       FROM store_sales ss2
       WHERE ss2.ss_customer_sk = ca.c_customer_sk
         AND ss2.ss_net_paid > 500) AS high_value_store_txn_cnt
FROM catalog_agg ca
LEFT JOIN store_sales ss
    ON ss.ss_customer_sk = ca.c_customer_sk
WHERE (ss.ss_wholesale_cost IS NULL OR ss.ss_wholesale_cost > 30)
  AND ca.order_cnt >= 5
  AND ca.max_ext_sales_price < 20000
ORDER BY ca.total_catalog_profit DESC
LIMIT 100
