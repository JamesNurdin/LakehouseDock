WITH aggregated_sales AS (
    SELECT
        cp.cp_type,
        cp.cp_catalog_page_number,
        c.c_birth_year,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_coupon_amt) AS avg_coupon
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451500
      AND cs.cs_coupon_amt > 0.00
      AND cs.cs_ext_list_price > 1000.00
      AND ca_bill.ca_state = 'CA'
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND cs.cs_ext_sales_price IS NOT NULL
    GROUP BY
        cp.cp_type,
        cp.cp_catalog_page_number,
        c.c_birth_year,
        ca_bill.ca_state,
        ca_ship.ca_state
),
scalar_avg_sales AS (
    SELECT AVG(cs_inner.cs_ext_sales_price) AS avg_sales_price
    FROM catalog_sales cs_inner
)
SELECT
    agg.cp_type,
    agg.cp_catalog_page_number,
    agg.c_birth_year,
    agg.bill_state,
    agg.ship_state,
    agg.total_sales,
    agg.total_profit,
    agg.sales_cnt,
    agg.avg_coupon,
    -- correlated subquery returning count of distinct shipping addresses for the same bill and ship state
    (
        SELECT COUNT(DISTINCT cs2.cs_ship_addr_sk)
        FROM catalog_sales cs2
        JOIN customer_address ca2 ON cs2.cs_ship_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_state = agg.ship_state
          AND ca2.ca_state = agg.bill_state
    ) AS same_state_ship_cnt,
    -- compare total_sales against overall average sales price (scalar subquery)
    CASE
        WHEN agg.total_sales > (SELECT avg_sales_price FROM scalar_avg_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_vs_avg,
    -- window functions
    RANK() OVER (PARTITION BY agg.cp_type ORDER BY agg.total_sales DESC) AS sales_rank,
    SUM(agg.total_sales) OVER (PARTITION BY agg.bill_state) AS total_sales_by_bill_state
FROM aggregated_sales agg
WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs_exists
        JOIN customer_address ca_exists ON cs_exists.cs_ship_addr_sk = ca_exists.ca_address_sk
        WHERE ca_exists.ca_state = agg.ship_state
          AND cs_exists.cs_ext_sales_price > agg.avg_coupon * 10
    )
  AND agg.total_profit > 0
  AND agg.sales_cnt >= 5
ORDER BY agg.total_sales DESC
LIMIT 50
