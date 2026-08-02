WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_ext_discount_amt,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_net_paid_inc_ship_tax < 5000
      AND cs.cs_quantity >= 2
      AND cs.cs_net_profit > (
          SELECT AVG(cs2.cs_net_profit)
          FROM catalog_sales cs2
          WHERE cs2.cs_ship_customer_sk = 577674
      )
),
aggregated_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cp.cp_catalog_page_number,
        cp.cp_department,
        ca.ca_state,
        CASE
            WHEN fs.cs_quantity > 5 THEN 'Large'
            ELSE 'Small'
        END AS order_size_category,
        SUM(fs.cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
        AVG(fs.cs_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax,
        COUNT(fs.cs_order_number) AS order_count,
        MIN(fs.cs_ext_discount_amt) AS min_discount,
        MAX(fs.cs_ext_sales_price) AS max_sales_price,
        SUM(fs.cs_ext_discount_amt) AS total_discount
    FROM call_center cc
    FULL OUTER JOIN filtered_sales fs
        ON cc.cc_call_center_sk = fs.cs_call_center_sk
    LEFT JOIN catalog_page cp
        ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        AND cp.cp_catalog_page_number IN (7, 8, 12)
    LEFT JOIN customer_address ca
        ON fs.cs_bill_addr_sk = ca.ca_address_sk
        AND ca.ca_country = 'United States'
        AND ca.ca_state = 'CA'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cp.cp_catalog_page_number,
        cp.cp_department,
        ca.ca_state,
        CASE
            WHEN fs.cs_quantity > 5 THEN 'Large'
            ELSE 'Small'
        END
)
SELECT
    cc_call_center_id,
    cc_name,
    cp_catalog_page_number,
    cp_department,
    ca_state,
    order_size_category,
    total_net_paid_inc_ship,
    avg_net_paid_inc_ship_tax,
    order_count,
    min_discount,
    max_sales_price,
    total_discount,
    RANK() OVER (ORDER BY total_net_paid_inc_ship DESC) AS net_paid_rank,
    SUM(total_net_paid_inc_ship) OVER (
        PARTITION BY cc_name
        ORDER BY total_net_paid_inc_ship
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid_by_center
FROM aggregated_sales
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
