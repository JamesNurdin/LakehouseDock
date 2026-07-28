WITH combined AS (
    SELECT
        d1.d_year,
        i.i_brand,
        i.i_brand_id,
        p.p_promo_name,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d1
        ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
       AND p.p_start_date_sk = d1.d_date_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
      AND i.i_brand_id = 6012006
      AND p.p_discount_active = 'Y'
      AND sr.sr_store_sk = 80
)
SELECT
    d_year,
    i_brand,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(cr_net_loss + sr_net_loss) AS total_net_loss,
    COUNT(*) AS transaction_count,
    AVG(cr_return_amount + sr_return_amt) AS avg_combined_return_amount
FROM combined
GROUP BY d_year, i_brand
HAVING SUM(cr_net_loss + sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 10
