WITH store_sales_monthly AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        CAST(ss.ss_sold_date_sk / 100 AS INTEGER) AS month_key,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ss.ss_customer_sk, CAST(ss.ss_sold_date_sk / 100 AS INTEGER)
),
catalog_sales_monthly AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        CAST(cs.cs_sold_date_sk / 100 AS INTEGER) AS month_key,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_division = 3
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY cs.cs_bill_customer_sk, CAST(cs.cs_sold_date_sk / 100 AS INTEGER)
),
sales_combined AS (
    SELECT
        COALESCE(ss.cust_sk, cs.cust_sk) AS cust_sk,
        COALESCE(ss.month_key, cs.month_key) AS month_key,
        ss.store_net_profit,
        ss.store_sales_amount,
        ss.store_quantity,
        cs.catalog_net_profit,
        cs.catalog_sales_amount,
        cs.catalog_quantity
    FROM store_sales_monthly ss
    FULL OUTER JOIN catalog_sales_monthly cs
        ON ss.cust_sk = cs.cust_sk AND ss.month_key = cs.month_key
),
web_returns_monthly AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        CAST(wr.wr_returned_date_sk / 100 AS INTEGER) AS month_key,
        SUM(wr.wr_net_loss) AS returns_net_loss,
        SUM(wr.wr_return_quantity) AS returns_quantity,
        SUM(wr.wr_return_amt) AS returns_amount
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY wr.wr_refunded_customer_sk, CAST(wr.wr_returned_date_sk / 100 AS INTEGER)
),
final AS (
    SELECT
        sc.cust_sk,
        sc.month_key,
        COALESCE(sc.store_net_profit, 0) + COALESCE(sc.catalog_net_profit, 0) - COALESCE(wr.returns_net_loss, 0) AS net_profit_combined,
        COALESCE(sc.store_sales_amount, 0) + COALESCE(sc.catalog_sales_amount, 0) - COALESCE(wr.returns_amount, 0) AS net_sales_amount,
        COALESCE(sc.store_quantity, 0) + COALESCE(sc.catalog_quantity, 0) - COALESCE(wr.returns_quantity, 0) AS net_quantity
    FROM sales_combined sc
    LEFT JOIN web_returns_monthly wr
        ON sc.cust_sk = wr.cust_sk AND sc.month_key = wr.month_key
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    f.month_key,
    f.net_profit_combined,
    f.net_sales_amount,
    f.net_quantity,
    RANK() OVER (PARTITION BY f.month_key ORDER BY f.net_profit_combined DESC) AS month_rank
FROM final f
JOIN customer c ON f.cust_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_country = 'United States'
ORDER BY f.net_profit_combined DESC
LIMIT 200
