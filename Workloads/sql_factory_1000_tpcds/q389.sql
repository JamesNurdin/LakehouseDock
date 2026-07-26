WITH sales_per_customer AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
),
returns_per_customer AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
category_rank AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        i.i_category AS category_name,
        SUM(cs.cs_quantity) AS category_qty,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY SUM(cs.cs_quantity) DESC) AS rn
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cs.cs_bill_customer_sk, i.i_category
),
promo_usage AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT cs.cs_promo_sk) AS promo_count,
        MAX(p.p_discount_active) AS any_promo_active
    FROM catalog_sales cs
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY cs.cs_bill_customer_sk
)
SELECT
    sc.customer_sk,
    sc.total_net_paid,
    sc.total_discount_amount,
    sc.total_sales_amount,
    CASE 
        WHEN sc.total_sales_amount = 0 THEN 0
        ELSE sc.total_discount_amount / sc.total_sales_amount
    END AS discount_ratio,
    sc.total_sales_profit,
    COALESCE(rp.total_return_loss, 0) AS total_return_loss,
    sc.total_sales_profit - COALESCE(rp.total_return_loss, 0) AS net_profit_after_returns,
    RANK() OVER (ORDER BY sc.total_sales_profit - COALESCE(rp.total_return_loss, 0) DESC) AS profit_rank,
    SUM(sc.total_sales_profit - COALESCE(rp.total_return_loss, 0)) OVER (ORDER BY sc.total_sales_profit - COALESCE(rp.total_return_loss, 0) ROWS UNBOUNDED PRECEDING) AS cumulative_profit,
    CASE 
        WHEN (sc.total_discount_amount / NULLIF(sc.total_sales_amount, 0)) > 0.10 THEN 'High Discount'
        ELSE 'Normal Discount'
    END AS discount_category,
    cr.category_name AS top_category,
    CASE 
        WHEN pu.promo_count > 0 AND pu.any_promo_active = 'Y' THEN 'Used Promotion'
        ELSE 'No Promotion'
    END AS promotion_usage
FROM sales_per_customer sc
LEFT JOIN returns_per_customer rp
    ON sc.customer_sk = rp.customer_sk
LEFT JOIN (
    SELECT customer_sk, category_name
    FROM category_rank
    WHERE rn = 1
) cr
    ON sc.customer_sk = cr.customer_sk
LEFT JOIN promo_usage pu
    ON sc.customer_sk = pu.customer_sk
ORDER BY profit_rank
LIMIT 20
