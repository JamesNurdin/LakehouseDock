WITH joined_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_coupon_amt,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        (cs.cs_quantity * cs.cs_sales_price) AS total_sales,
        p.p_promo_name,
        p.p_purpose,
        p.p_channel_tv
    FROM
        catalog_sales cs
    JOIN
        promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        cs.cs_quantity > 5
        AND cs.cs_sales_price > 100
        AND cs.cs_coupon_amt < 500
        AND cs.cs_ship_mode_sk IN (1, 2, 3)
        AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451175
        AND p.p_purpose = 'Unknown'
        AND p.p_channel_tv = 'N'
), ranked_sales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY cs_promo_sk ORDER BY total_sales DESC) AS promo_rank
    FROM
        joined_sales
)
SELECT
    cs_order_number,
    cs_item_sk,
    cs_quantity,
    cs_sales_price,
    cs_coupon_amt,
    total_sales,
    p_promo_name,
    p_purpose,
    promo_rank
FROM
    ranked_sales
WHERE
    promo_rank <= 3
ORDER BY
    cs_promo_sk,
    promo_rank,
    total_sales DESC
LIMIT 100
