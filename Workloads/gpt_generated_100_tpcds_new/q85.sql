WITH sales_promo AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_coupon_amt,
        p.p_promo_name,
        p.p_channel_catalog,
        p.p_channel_radio
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_bill_cdemo_sk = 125317
      AND cs.cs_ship_cdemo_sk = 307069
      AND cs.cs_coupon_amt > 1000
      AND p.p_channel_catalog = 'N'
)
SELECT
    p_promo_name,
    p_channel_catalog,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_quantity) AS total_qty,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_coupon_amt) AS avg_coupon_amt,
    MIN(cs_net_paid) AS min_net_paid,
    MAX(cs_net_paid) AS max_net_paid
FROM sales_promo
GROUP BY p_promo_name, p_channel_catalog
ORDER BY total_net_paid DESC
LIMIT 100
