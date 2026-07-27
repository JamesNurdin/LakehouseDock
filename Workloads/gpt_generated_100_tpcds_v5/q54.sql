WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        hd.hd_income_band_sk,
        p.p_promo_name,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        w.w_state
    FROM catalog_sales cs
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE w.w_warehouse_sq_ft > 800000
      AND w.w_state = 'CA'
      AND hd.hd_income_band_sk IN (4, 10)
      AND p.p_start_date_sk BETWEEN 2450300 AND 2450400
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
)
SELECT
    w_warehouse_name,
    COALESCE(p_promo_name, 'No Promo') AS promo_name,
    hd_income_band_sk,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_discount_amt) AS avg_discount_amt,
    MIN(cs_net_paid) AS min_net_paid,
    MAX(cs_net_paid) AS max_net_paid
FROM filtered_sales
GROUP BY
    w_warehouse_name,
    COALESCE(p_promo_name, 'No Promo'),
    hd_income_band_sk
ORDER BY total_net_paid DESC
LIMIT 100
