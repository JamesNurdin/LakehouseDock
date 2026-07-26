WITH latest_promo AS (
    SELECT
        p.*, 
        ROW_NUMBER() OVER (PARTITION BY p.p_item_sk ORDER BY p.p_start_date_sk DESC) AS rn
    FROM promotion p
),
promo_latest AS (
    SELECT *
    FROM latest_promo
    WHERE rn = 1
),
brand_state_agg AS (
    SELECT
        ca.ca_state,
        i.i_brand,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(CASE WHEN pl.p_channel_email = 'Y' THEN sr.sr_return_quantity ELSE 0 END) AS email_promo_qty
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN promo_latest pl ON i.i_item_sk = pl.p_item_sk
    GROUP BY ca.ca_state, i.i_brand
),
ranked_brands AS (
    SELECT
        ca_state,
        i_brand,
        total_return_qty,
        total_return_amt,
        email_promo_qty,
        (email_promo_qty * 100.0) / NULLIF(total_return_qty, 0) AS email_promo_pct,
        DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_return_qty DESC) AS brand_state_rank
    FROM brand_state_agg
)
SELECT
    ca_state,
    i_brand,
    total_return_qty,
    total_return_amt,
    email_promo_qty,
    email_promo_pct,
    brand_state_rank
FROM ranked_brands
WHERE brand_state_rank <= 3
ORDER BY ca_state, brand_state_rank
