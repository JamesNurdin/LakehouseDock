WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_return_quantity,
        sr.sr_ticket_number,
        d.d_year,
        i.i_brand,
        i.i_current_price,
        i.i_product_name,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_demo
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                 -- filter 1
      AND i.i_current_price BETWEEN 10 AND 100            -- filter 2
      AND sr.sr_return_quantity > 0                       -- filter 3
      AND sr.sr_return_ship_cost > 20                     -- filter 4
      AND p.p_channel_demo = 'N'                          -- filter 5
      AND p.p_discount_active = 'Y'                       -- filter 6
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = sr.sr_hdemo_sk          -- join rule via semi‑join
            AND hd.hd_vehicle_count >= 1                 -- filter 7
            AND hd.hd_buy_potential = '1001-5000'        -- filter 8
      )
),
agg AS (
    SELECT
        d_year,
        i_brand,
        p_promo_name,
        COUNT(DISTINCT sr_ticket_number) AS distinct_tickets,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_ship_cost) AS avg_ship_cost,
        MIN(sr_return_amt) AS min_return_amt,
        MAX(sr_return_amt) AS max_return_amt
    FROM base
    GROUP BY d_year, i_brand, p_promo_name
    HAVING SUM(sr_return_amt) > 1000
)
SELECT
    d_year,
    i_brand,
    p_promo_name,
    distinct_tickets,
    total_return_amt,
    avg_ship_cost,
    min_return_amt,
    max_return_amt,
    CASE
        WHEN total_return_amt > 5000 THEN 'Very High'
        WHEN total_return_amt > 2000 THEN 'High'
        ELSE 'Normal'
    END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_return_amt DESC) AS brand_rank
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
