WITH
    sales_filtered AS (
        SELECT cs.cs_sold_date_sk,
               cs.cs_net_profit,
               cs.cs_ext_list_price,
               cs.cs_item_sk,
               cs.cs_ship_mode_sk,
               cs.cs_bill_customer_sk,
               cs.cs_ship_customer_sk,
               cs.cs_bill_cdemo_sk,
               cs.cs_catalog_page_sk
        FROM catalog_sales cs
        WHERE cs.cs_ext_list_price > 5000
          AND cs.cs_net_profit IS NOT NULL
    ),
    cust_filtered AS (
        SELECT c.c_customer_sk,
               c.c_birth_year,
               c.c_current_cdemo_sk
        FROM customer c
        WHERE c.c_birth_year BETWEEN 1970 AND 1980
    ),
    ship_cust_filtered AS (
        SELECT c.c_customer_sk,
               c.c_first_sales_date_sk
        FROM customer c
        WHERE c.c_first_sales_date_sk > 2450000
    ),
    cust_demo_filtered AS (
        SELECT cd.cd_demo_sk,
               cd.cd_gender,
               cd.cd_credit_rating
        FROM customer_demographics cd
        WHERE cd.cd_gender = 'M'
    ),
    page_filtered AS (
        SELECT cp.cp_catalog_page_sk,
               cp.cp_type
        FROM catalog_page cp
        WHERE cp.cp_type = 'C'
    ),
    ship_filtered AS (
        SELECT sm.sm_ship_mode_sk,
               sm.sm_type,
               sm.sm_contract,
               sm.sm_code
        FROM ship_mode sm
        WHERE sm.sm_contract IN ('GNJr3g5i7oorKqtX', 'HVDFCcQ')
          AND sm.sm_code = 'AIR'
    ),
    item_filtered AS (
        SELECT i.i_item_sk,
               i.i_category,
               i.i_current_price,
               i.i_rec_start_date
        FROM item i
        WHERE i.i_current_price >= 100
          AND i.i_rec_start_date >= DATE '2000-01-01'
    ),
    inventory_filtered AS (
        SELECT inv.inv_item_sk,
               inv.inv_quantity_on_hand
        FROM inventory inv
        WHERE inv.inv_quantity_on_hand > 0
    ),
    web_page_filtered AS (
        SELECT wp.wp_customer_sk,
               wp.wp_type
        FROM web_page wp
        WHERE wp.wp_type = 'home'
    ),
    agg AS (
        SELECT
            i.i_category,
            sm.sm_type,
            SUM(s.cs_net_profit) AS total_profit,
            COUNT(DISTINCT c.c_customer_sk) AS distinct_bill_customers,
            COUNT(DISTINCT sc.c_customer_sk) AS distinct_ship_customers
        FROM sales_filtered s
        JOIN cust_filtered c
            ON s.cs_bill_customer_sk = c.c_customer_sk
        JOIN ship_cust_filtered sc
            ON s.cs_ship_customer_sk = sc.c_customer_sk
        JOIN cust_demo_filtered cd
            ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN page_filtered p
            ON s.cs_catalog_page_sk = p.cp_catalog_page_sk
        JOIN ship_filtered sm
            ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN item_filtered i
            ON s.cs_item_sk = i.i_item_sk
        JOIN inventory_filtered inv
            ON i.i_item_sk = inv.inv_item_sk
        JOIN web_page_filtered wp
            ON wp.wp_customer_sk = c.c_customer_sk
        GROUP BY ROLLUP (i.i_category, sm.sm_type)
        HAVING SUM(s.cs_net_profit) > 1000
    )
SELECT
    agg.i_category,
    agg.sm_type,
    agg.total_profit,
    agg.distinct_bill_customers,
    agg.distinct_ship_customers,
    RANK() OVER (PARTITION BY agg.sm_type ORDER BY agg.total_profit DESC) AS category_rank_by_ship_mode
FROM agg
WHERE agg.i_category IS NOT NULL
ORDER BY agg.total_profit DESC
LIMIT 50
