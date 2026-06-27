WITH catalog_data AS (
    SELECT 
        d.d_date,
        i.i_category,
        i.i_item_id,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_net_paid AS net_paid,
        p.p_cost AS promo_cost,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
store_data AS (
    SELECT 
        d.d_date,
        i.i_category,
        i.i_item_id,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_ext_discount_amt AS ext_discount_amt,
        ss.ss_net_paid AS net_paid,
        p.p_cost AS promo_cost,
        p.p_discount_active
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
combined AS (
    SELECT 
        d_date,
        i_category,
        i_item_id,
        'catalog' AS sales_channel,
        quantity,
        ext_sales_price,
        ext_discount_amt,
        net_paid,
        promo_cost,
        p_discount_active
    FROM catalog_data
    UNION ALL
    SELECT 
        d_date,
        i_category,
        i_item_id,
        'store' AS sales_channel,
        quantity,
        ext_sales_price,
        ext_discount_amt,
        net_paid,
        promo_cost,
        p_discount_active
    FROM store_data
)
SELECT 
    date_trunc('month', d_date) AS month,
    i_category,
    sales_channel,
    SUM(quantity) AS total_quantity,
    SUM(ext_sales_price) AS total_sales,
    SUM(ext_discount_amt) AS total_discount,
    SUM(net_paid) AS total_net_paid,
    SUM(COALESCE(promo_cost, 0)) AS total_promo_cost,
    COUNT(*) AS transaction_count
FROM combined
GROUP BY 
    date_trunc('month', d_date),
    i_category,
    sales_channel
ORDER BY 
    month,
    i_category,
    sales_channel
