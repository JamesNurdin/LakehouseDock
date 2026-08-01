WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        c.c_customer_id,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MAX(cs.cs_ext_list_price) AS max_list_price,
        SUM(CASE WHEN sr.sr_ticket_number IS NOT NULL THEN sr.sr_return_amt ELSE 0 END) AS total_returns_amount
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_ext_list_price > 8000
      AND cs.cs_ext_ship_cost < 1000
      AND ss.ss_quantity >= 2
      AND cd.cd_dep_employed_count >= 3
      AND td.t_hour BETWEEN 9 AND 17
      AND cp.cp_type = 'PROMO'
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_ticket_number = ss.ss_ticket_number
            AND sr2.sr_return_time_sk = td.t_time_sk
      )
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        c.c_customer_id
),
ranked AS (
    SELECT
        cp_catalog_page_id,
        cp_department,
        cp_type,
        distinct_customers,
        total_catalog_sales,
        total_store_sales,
        total_store_net_profit,
        avg_discount,
        max_list_price,
        total_returns_amount,
        ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_store_net_profit DESC) AS dept_profit_rank
    FROM base
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_type,
    distinct_customers,
    total_catalog_sales,
    total_store_sales,
    total_store_net_profit,
    avg_discount,
    max_list_price,
    total_returns_amount,
    dept_profit_rank,
    (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS overall_avg_store_net_paid
FROM ranked
ORDER BY total_store_net_profit DESC
LIMIT 100
