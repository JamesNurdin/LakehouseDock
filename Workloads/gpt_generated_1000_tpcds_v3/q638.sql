WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d.d_year,
        sm.sm_code,
        p.p_discount_active,
        SUM(cs.cs_ext_sales_price) AS cs_sales,
        SUM(ws.ws_ext_sales_price) AS ws_sales,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
        AND sm.sm_code IN ('AIR', 'SEA')
        AND p.p_discount_active = 'Y'
        AND cs.cs_quantity > 10
        AND ws.ws_quantity > 5
    GROUP BY cs.cs_order_number,
             cs.cs_sold_date_sk,
             ws.ws_order_number,
             ws.ws_sold_date_sk,
             d.d_year,
             sm.sm_code,
             p.p_discount_active
)
SELECT
    d_year,
    sm_code,
    p_discount_active,
    total_catalog_sales,
    total_web_sales,
    avg_sales_per_transaction,
    overall_avg_catalog_price
FROM (
    SELECT
        d_year,
        sm_code,
        p_discount_active,
        SUM(cs_sales) AS total_catalog_sales,
        SUM(ws_sales) AS total_web_sales,
        SUM(cs_sales + ws_sales) / NULLIF(SUM(txn_count), 0) AS avg_sales_per_transaction,
        (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) AS overall_avg_catalog_price
    FROM sales_agg
    GROUP BY d_year, sm_code, p_discount_active
    HAVING SUM(cs_sales) > 2000
) agg
WHERE total_catalog_sales > 10000
  AND total_web_sales > 5000
ORDER BY total_catalog_sales DESC, d_year
LIMIT 100
