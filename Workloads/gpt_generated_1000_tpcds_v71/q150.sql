WITH catalog AS (
    SELECT
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS total_sales,
        'catalog' AS source
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND hd.hd_vehicle_count > 0
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date, p.p_promo_name
),
web AS (
    SELECT
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_paid) AS total_sales,
        'web' AS source
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND hd.hd_vehicle_count > 0
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date, p.p_promo_name
)
SELECT sale_date, promo_name, total_sales, source
FROM catalog
UNION ALL
SELECT sale_date, promo_name, total_sales, source
FROM web
ORDER BY sale_date DESC, total_sales DESC
LIMIT 100
