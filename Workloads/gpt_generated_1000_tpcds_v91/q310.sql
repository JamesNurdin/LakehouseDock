WITH sales_returns AS (
    SELECT
        cs.cs_order_number AS order_num,
        d_sales.d_date AS activity_date,
        cs.cs_net_paid AS net_paid,
        cr.cr_return_amount AS return_amount,
        (cs.cs_net_paid - cr.cr_return_amount) AS net_after_return,
        c.c_customer_id AS customer_id,
        cp.cp_catalog_page_id AS catalog_page_id,
        CAST(NULL AS varchar) AS channel,
        (
            SELECT AVG(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_start_date_sk = d_sales.d_date_sk
        ) AS metric
    FROM catalog_sales cs
    INNER JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d_sales.d_year = 2001
      AND d_sales.d_weekend = 'N'
),

promotion_channels AS (
    SELECT
        CAST(NULL AS integer) AS order_num,
        d_promo.d_date AS activity_date,
        CAST(NULL AS decimal(7,2)) AS net_paid,
        CAST(NULL AS decimal(7,2)) AS return_amount,
        CAST(NULL AS decimal(7,2)) AS net_after_return,
        CAST(NULL AS varchar) AS customer_id,
        cp.cp_catalog_page_id AS catalog_page_id,
        TRIM(t.channel) AS channel,
        p.p_cost AS metric
    FROM promotion p
    INNER JOIN date_dim d_promo
        ON p.p_start_date_sk = d_promo.d_date_sk
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_promo.d_date_sk
    CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
    WHERE d_promo.d_year = 2001
      AND d_promo.d_weekend = 'N'
)

SELECT
    order_num,
    activity_date,
    net_paid,
    return_amount,
    net_after_return,
    customer_id,
    catalog_page_id,
    channel,
    metric
FROM sales_returns
UNION ALL
SELECT
    order_num,
    activity_date,
    net_paid,
    return_amount,
    net_after_return,
    customer_id,
    catalog_page_id,
    channel,
    metric
FROM promotion_channels
LIMIT 100
