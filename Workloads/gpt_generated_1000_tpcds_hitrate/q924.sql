WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_net_loss,
        ARRAY[cr.cr_return_amount, cr.cr_return_tax] AS return_vals
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 10
      AND cr.cr_return_tax BETWEEN 0 AND 50
),
promo_start AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_email,
        p.p_item_sk,
        p.p_start_date_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
      AND p.p_promo_name IS NOT NULL
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_discount_active, p.p_channel_email, p.p_item_sk, p.p_start_date_sk
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    i.i_brand,
    ps.p_promo_name,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(b.cr_return_amount) AS total_return_amount,
    AVG(b.cr_return_tax) AS avg_return_tax,
    MIN(b.cr_fee) AS min_fee,
    MAX(b.cr_net_loss) AS max_net_loss,
    SUM(CASE WHEN b.cr_return_amount > (
            SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2
        ) THEN 1 ELSE 0 END) AS high_amount_returns,
    t.return_val AS individual_return_value
FROM base b
JOIN date_dim d ON b.cr_returned_date_sk = d.d_date_sk
JOIN item i ON b.cr_item_sk = i.i_item_sk
JOIN warehouse w ON b.cr_warehouse_sk = w.w_warehouse_sk
JOIN promo_start ps ON i.i_item_sk = ps.p_item_sk AND ps.p_start_date_sk = d.d_date_sk
JOIN customer c ON b.cr_refunded_customer_sk = c.c_customer_sk
CROSS JOIN UNNEST(b.return_vals) AS t(return_val)
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND w.w_state = 'CA'
  AND EXISTS (SELECT 1 FROM warehouse w2 WHERE w2.w_city = 'Seattle')
GROUP BY d.d_year, w.w_warehouse_name, i.i_brand, ps.p_promo_name, t.return_val
ORDER BY total_return_amount DESC
LIMIT 100
