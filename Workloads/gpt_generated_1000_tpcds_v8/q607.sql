WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        d_sold.d_year AS sold_year,
        d_ship.d_month_seq AS ship_month_seq,
        cc.cc_division,
        cc.cc_market_manager,
        sm.sm_type,
        sm.sm_contract,
        p.p_promo_name,
        CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'HIGH' ELSE 'LOW' END AS price_category,
        ARRAY[cs.cs_quantity, cs.cs_ship_mode_sk] AS int_array
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    FULL OUTER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_division IN (1, 2, 3, 4)                         -- filter 1
      AND sm.sm_contract LIKE 'A%'                              -- filter 2
      AND d_sold.d_year BETWEEN 1999 AND 2001                    -- filter 3
      AND cs.cs_ext_sales_price IS NOT NULL                     -- filter 4
),
expanded AS (
    SELECT
        b.*, 
        lt.element AS array_element
    FROM base b
    CROSS JOIN LATERAL (
        SELECT element
        FROM UNNEST(b.int_array) AS u(element)
    ) lt
),
agg1 AS (
    SELECT
        price_category,
        sold_year,
        sm_type,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt,
        AVG(cs_quantity) AS avg_quantity
    FROM expanded
    GROUP BY ROLLUP (price_category, sold_year, sm_type)
)
SELECT
    price_category,
    sold_year,
    sm_type,
    total_sales,
    total_profit,
    transaction_cnt,
    avg_quantity,
    RANK() OVER (PARTITION BY price_category ORDER BY total_sales DESC) AS sales_rank
FROM agg1
WHERE total_sales > 5000
ORDER BY price_category, total_sales DESC, sm_type
LIMIT 100
