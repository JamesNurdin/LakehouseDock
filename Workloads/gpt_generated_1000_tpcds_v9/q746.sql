WITH ss_agg AS (
    SELECT
        ss_ticket_number,
        ss_item_sk,
        ss_sold_date_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_addr_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_sales_price) AS avg_sales_price
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_ticket_number, ss_item_sk, ss_sold_date_sk, ss_customer_sk, ss_cdemo_sk, ss_addr_sk
),
union_items AS (
    SELECT DISTINCT ss_item_sk AS item_sk FROM store_sales
    UNION
    SELECT DISTINCT cs_item_sk FROM catalog_sales
)
SELECT
    d.d_year,
    cc.cc_name,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ss_agg.ss_ticket_number) AS distinct_orders,
    SUM(ss_agg.total_sales) AS sum_store_sales,
    SUM(sr.sr_return_amt) AS sum_return_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    MIN(ss_agg.total_sales) AS min_store_sale,
    MAX(ss_agg.total_sales) AS max_store_sale
FROM ss_agg
JOIN store_returns sr
    ON sr.sr_ticket_number = ss_agg.ss_ticket_number
   AND sr.sr_item_sk = ss_agg.ss_item_sk
JOIN date_dim d
    ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
   AND cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss_agg.ss_addr_sk = ca.ca_address_sk
   AND cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
   AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 1998
  AND cc.cc_manager IN ('Ronnie Trinidad', 'Jack Little')
  AND cc.cc_employees > 2000000
  AND cd.cd_dep_college_count = 2
  AND ca.ca_state = 'CA'
  AND sr.sr_return_ship_cost > 50.00
  AND ss_agg.ss_ticket_number NOT IN (
        SELECT DISTINCT ss_ticket_number
        FROM store_sales
        WHERE ss_quantity > 1000
    )
  AND EXISTS (
        SELECT 1
        FROM union_items ui
        WHERE ui.item_sk = ss_agg.ss_item_sk
    )
GROUP BY d.d_year, cc.cc_name, ca.ca_state, cd.cd_gender
ORDER BY sum_store_sales DESC
LIMIT 100
