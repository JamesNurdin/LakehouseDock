/*
Goal: Identify the top stores (by total net loss from both store and web returns) that meet several business criteria, showing price category, distinct customer and item counts, and expanding store location into separate rows. The query joins all eight selected TPC‑DS tables, applies multiple filters, uses a CASE expression, computes distinct aggregates, ranks stores with a window function, excludes stores that have very large single returns via an anti‑semi‑join, and demonstrates UNNEST of an array of location fields.
*/
WITH base AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_country,
        i.i_item_id,
        i.i_current_price,
        cd.cd_gender,
        ib.ib_upper_bound,
        sr.sr_net_loss,
        wr.wr_net_loss,
        sr.sr_fee,
        wr.wr_fee,
        c.c_customer_id
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_market_manager = 'David Lamontagne'
      AND ib.ib_upper_bound >= 100000
      AND i.i_current_price BETWEEN 10 AND 100
      AND sr.sr_fee > 5
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND sr.sr_return_quantity > 0
),
agg AS (
    SELECT
        sr_store_sk,
        s_store_id,
        s_store_name,
        s_state,
        s_city,
        s_country,
        CASE WHEN i_current_price > 80 THEN 'HIGH' ELSE 'LOW' END AS price_category,
        SUM(sr_net_loss + wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        COUNT(DISTINCT i_item_id) AS distinct_items
    FROM base
    GROUP BY
        sr_store_sk,
        s_store_id,
        s_store_name,
        s_state,
        s_city,
        s_country,
        i_current_price
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
    FROM agg
    WHERE sr_store_sk NOT IN (
        SELECT sr_store_sk FROM store_returns WHERE sr_return_amt > 5000
    )
)
SELECT
    sr_store_sk,
    s_store_id,
    s_store_name,
    price_category,
    total_net_loss,
    loss_rank,
    distinct_customers,
    distinct_items,
    loc_part AS location_part
FROM ranked
CROSS JOIN UNNEST(ARRAY[s_state, s_city, s_country]) AS t(loc_part)
ORDER BY loss_rank
LIMIT 100
