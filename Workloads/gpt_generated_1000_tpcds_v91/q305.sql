WITH cs_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_id,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_ext_discount_amt AS discount_amount,
        CASE WHEN cs.cs_quantity > 5 THEN 'LARGE' ELSE 'SMALL' END AS qty_category
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND p.p_channel_radio = 'N'
      AND cs.cs_ship_hdemo_sk = 5715
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_promo_sk = p.p_promo_sk
            AND ws.ws_net_paid_inc_tax > 500
      )
),
ws_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_id,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_ext_discount_amt AS discount_amount,
        CASE WHEN ws.ws_quantity > 5 THEN 'LARGE' ELSE 'SMALL' END AS qty_category
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ext_sales_price > 1000
      AND p.p_channel_radio = 'N'
      AND ws.ws_web_site_sk = 21
),
all_sales AS (
    SELECT * FROM cs_data
    UNION ALL
    SELECT * FROM ws_data
),
aggregated AS (
    SELECT
        qty_category,
        p_promo_id,
        SUM(sales_amount) AS total_sales,
        AVG(discount_amount) AS avg_discount,
        COUNT(*) AS order_cnt,
        MIN(sales_amount) AS min_sales,
        MAX(sales_amount) AS max_sales
    FROM all_sales
    GROUP BY ROLLUP (qty_category, p_promo_id)
)
SELECT
    qty_category,
    p_promo_id,
    total_sales,
    avg_discount,
    order_cnt,
    min_sales,
    max_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
