/*
  Goal: Identify high‑earning call center locations (state & city) where total sales exceed $200,000, exclude locations whose sales fall in the $100k‑$200k range, show subtotals and grand total via ROLLUP, and include per‑location total coupon amount as a correlated scalar subquery. Results are paginated.
*/
WITH agg_sales AS (
    SELECT
        cc.cc_state,
        cc.cc_city,
        cc.cc_call_center_sk,
        SUM(cs.cs_ext_sales_price)   AS sales_amount,
        SUM(cs.cs_ext_ship_cost)     AS ship_cost
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY ROLLUP (cc.cc_state, cc.cc_city, cc.cc_call_center_sk)
)
,
high_sales AS (
    SELECT
        cc_state AS state,
        cc_city  AS city,
        sales_amount,
        ship_cost,
        cc_call_center_sk
    FROM agg_sales
    WHERE cc_state IS NOT NULL
      AND cc_city IS NOT NULL
      AND sales_amount > 200000
),
mid_sales AS (
    SELECT
        cc_state AS state,
        cc_city  AS city,
        sales_amount,
        ship_cost,
        cc_call_center_sk
    FROM agg_sales
    WHERE cc_state IS NOT NULL
      AND cc_city IS NOT NULL
      AND sales_amount BETWEEN 100000 AND 200000
)
SELECT
    hs.state,
    hs.city,
    hs.sales_amount,
    hs.ship_cost,
    (
        SELECT SUM(cs2.cs_coupon_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = hs.cc_call_center_sk
    ) AS total_coupon_amt
FROM high_sales hs
EXCEPT
SELECT
    ms.state,
    ms.city,
    ms.sales_amount,
    ms.ship_cost,
    (
        SELECT SUM(cs2.cs_coupon_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = ms.cc_call_center_sk
    ) AS total_coupon_amt
FROM mid_sales ms
ORDER BY state, city
OFFSET 10
LIMIT 100
