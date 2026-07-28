WITH catalog_agg AS (
    SELECT
        ca_bill.ca_city AS city,
        ca_bill.ca_gmt_offset AS gmt_offset,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        COUNT(*) AS txn_cnt,
        RANK() OVER (PARTITION BY ca_bill.ca_city ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS city_rank
    FROM catalog_sales cs
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450817 AND 2450831
      AND cs.cs_warehouse_sk IN (10, 15)
      AND ca_bill.ca_city = 'Springfield'
      AND ca_bill.ca_gmt_offset = -8.00
    GROUP BY ca_bill.ca_city, ca_bill.ca_gmt_offset
),
store_agg AS (
    SELECT
        ca_store.ca_city AS city,
        ca_store.ca_gmt_offset AS gmt_offset,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        COUNT(*) AS txn_cnt,
        RANK() OVER (PARTITION BY ca_store.ca_city ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS city_rank
    FROM store_sales ss
    JOIN customer_address ca_store
        ON ss.ss_addr_sk = ca_store.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450817 AND 2450831
      AND ss.ss_sales_price > 0
      AND ca_store.ca_city = 'Springfield'
      AND ca_store.ca_gmt_offset = -8.00
    GROUP BY ca_store.ca_city, ca_store.ca_gmt_offset
)
SELECT
    city,
    gmt_offset,
    sales_amount,
    txn_cnt,
    city_rank,
    source,
    ROW_NUMBER() OVER (ORDER BY sales_amount DESC) AS overall_rank
FROM (
    SELECT city, gmt_offset, sales_amount, txn_cnt, city_rank, 'catalog' AS source
    FROM catalog_agg
    UNION ALL
    SELECT city, gmt_offset, sales_amount, txn_cnt, city_rank, 'store'   AS source
    FROM store_agg
) combined
ORDER BY overall_rank
LIMIT 100
