WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        ss_ticket_number,
        ss_customer_sk,
        ss_addr_sk,
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM tpcds.store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2452000               -- predicate 1
      AND ss_ext_sales_price > 0                                 -- predicate 2
      AND ss_quantity > 0                                         -- predicate 3
    GROUP BY ss_item_sk, ss_sold_date_sk, ss_ticket_number,
             ss_customer_sk, ss_addr_sk, ss_hdemo_sk
),
joined_data AS (
    SELECT
        COALESCE(sa.ss_sold_date_sk, sr.sr_returned_date_sk) AS date_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        COALESCE(sa.total_sales, 0) - COALESCE(sr.sr_return_amt, 0) AS net_sales,
        CASE
            WHEN COALESCE(sa.total_sales, 0) > 10000 THEN 'HIGH'
            WHEN COALESCE(sa.total_sales, 0) > 5000  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_category,
        c.c_customer_id,
        ca.ca_state,
        hd.hd_buy_potential,
        COUNT(DISTINCT c.c_customer_id) OVER (PARTITION BY i.i_category) AS distinct_customers_in_category,
        COUNT(DISTINCT i.i_brand)      OVER (PARTITION BY i.i_category) AS distinct_brands_in_category,
        RANK() OVER (PARTITION BY i.i_category ORDER BY COALESCE(sa.total_sales, 0) DESC) AS sales_rank_in_category,
        (SELECT AVG(i_current_price)
         FROM tpcds.item
         WHERE i_category = i.i_category) AS avg_price_in_category
    FROM sales_agg sa
    FULL OUTER JOIN tpcds.store_returns sr
        ON sa.ss_ticket_number = sr.sr_ticket_number
       AND sa.ss_item_sk      = sr.sr_item_sk
    LEFT JOIN tpcds.item i
        ON COALESCE(sa.ss_item_sk, sr.sr_item_sk) = i.i_item_sk
    LEFT JOIN tpcds.customer c
        ON COALESCE(sa.ss_customer_sk, sr.sr_customer_sk) = c.c_customer_sk
    LEFT JOIN tpcds.customer_address ca
        ON COALESCE(sa.ss_addr_sk, sr.sr_addr_sk) = ca.ca_address_sk
    LEFT JOIN tpcds.household_demographics hd
        ON COALESCE(sa.ss_hdemo_sk, sr.sr_hdemo_sk) = hd.hd_demo_sk
    WHERE i.i_category_id IN (2, 4, 7)                -- predicate 4
      AND c.c_birth_month IN (1, 3, 5, 9)           -- predicate 5
      AND hd.hd_dep_count BETWEEN 1 AND 7          -- predicate 6
      AND ca.ca_country = 'United States'          -- predicate 7
      AND i.i_formulation LIKE '%ivory%'           -- predicate 8
      AND (CASE WHEN i.i_current_price IS NULL THEN 0 ELSE i.i_current_price END) > 10  -- predicate 9
)
SELECT
    date_sk,
    i_item_id,
    i_category,
    i_brand,
    net_sales,
    sales_category,
    c_customer_id,
    ca_state,
    hd_buy_potential,
    distinct_customers_in_category,
    distinct_brands_in_category,
    sales_rank_in_category,
    avg_price_in_category
FROM joined_data
WHERE net_sales IS NOT NULL
ORDER BY net_sales DESC, sales_rank_in_category
LIMIT 100
