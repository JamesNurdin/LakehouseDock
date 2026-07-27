WITH base AS (
    SELECT
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        sr.sr_return_amt,
        sr.sr_fee,
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        p.p_promo_id,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_channel_demo = 'N'
      AND sr.sr_fee > 20
      AND c.c_birth_year = 1985
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
            AND ws2.ws_quantity > 5
            AND ws2.ws_sold_date_sk = cs.cs_sold_date_sk
      )
),
agg AS (
    SELECT
        p_id,
        warehouse_name,
        gender,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        SUM(catalog_sales_ext_sales) AS total_catalog_sales,
        SUM(web_sales_ext_sales) AS total_web_sales,
        AVG(return_amount) AS avg_return_amount,
        MIN(return_fee) AS min_return_fee,
        MAX(return_fee) AS max_return_fee,
        SUM(catalog_sales_ext_sales + web_sales_ext_sales) AS total_combined_sales
    FROM (
        SELECT
            c_customer_sk AS customer_sk,
            cd_gender AS gender,
            p_promo_id AS p_id,
            w_warehouse_name AS warehouse_name,
            cs_ext_sales_price AS catalog_sales_ext_sales,
            ws_ext_sales_price AS web_sales_ext_sales,
            sr_return_amt AS return_amount,
            sr_fee AS return_fee
        FROM base
    ) x
    GROUP BY p_id, warehouse_name, gender
)
SELECT
    p_id,
    warehouse_name,
    gender,
    distinct_customers,
    total_catalog_sales,
    total_web_sales,
    avg_return_amount,
    min_return_fee,
    max_return_fee,
    total_combined_sales,
    SUM(total_combined_sales) OVER (
        PARTITION BY p_id
        ORDER BY total_combined_sales DESC
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_sales_by_promo
FROM agg
ORDER BY total_combined_sales DESC
LIMIT 100
