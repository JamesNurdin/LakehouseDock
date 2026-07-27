WITH distinct_sites AS (
   SELECT DISTINCT web_site_sk
   FROM web_site
   WHERE web_company_id IN (1, 3, 5)               -- filter: specific companies
     AND web_state = 'CA'                         -- filter: sites in California
),

sales_agg AS (
   SELECT
       ws_promo_sk,
       ws_web_site_sk,
       SUM(ws_ext_sales_price) AS total_sales,
       SUM(ws_coupon_amt) AS total_coupons,
       COUNT(DISTINCT ws_order_number) AS distinct_orders
   FROM web_sales
   WHERE ws_sales_price > 20.00                 -- filter: meaningful sales price
     AND ws_ext_wholesale_cost < 5000.00        -- filter: reasonable wholesale cost
     AND ws_quantity >= 1                      -- filter: at least one unit sold
   GROUP BY ws_promo_sk, ws_web_site_sk
),

promo_filtered AS (
   SELECT
       p_promo_sk,
       p_promo_name,
       p_channel_radio,
       p_purpose
   FROM promotion
   WHERE p_channel_radio = 'N'                 -- filter: radio channel not used
     AND p_purpose = 'Unknown'                  -- filter: unknown purpose promotions
)

SELECT
    ws.web_company_name,
    pf.p_promo_name,
    SUM(sa.total_sales) AS sum_sales,
    SUM(sa.total_coupons) AS sum_coupons,
    SUM(sa.distinct_orders) AS total_orders,
    AVG(sa.total_sales - sa.total_coupons) AS avg_net_sales
FROM sales_agg sa
JOIN promo_filtered pf
    ON sa.ws_promo_sk = pf.p_promo_sk
JOIN web_site ws
    ON sa.ws_web_site_sk = ws.web_site_sk
JOIN distinct_sites ds
    ON ws.web_site_sk = ds.web_site_sk
GROUP BY ws.web_company_name, pf.p_promo_name
HAVING SUM(sa.total_sales) > 1000.00               -- keep only groups with significant sales
ORDER BY sum_sales DESC
LIMIT 100
