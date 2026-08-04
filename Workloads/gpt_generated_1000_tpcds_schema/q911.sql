WITH sampled_store AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        p.p_promo_sk,
        p.p_promo_id,
        p.p_discount_active,
        ws.ws_net_paid_inc_tax,
        ws.ws_list_price,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        wp.wp_type,
        wp.wp_rec_start_date,
        ws2.web_site_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        -- scalar sub‑query: average list price for the same web site
        (SELECT avg(ws_sub.ws_list_price)
         FROM web_sales ws_sub
         WHERE ws_sub.ws_web_site_sk = ws2.web_site_sk) AS avg_site_price
    FROM sampled_store ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk   -- use bill side to keep left‑deep chain
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws2
        ON ws.ws_web_site_sk = ws2.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count > 1                     -- predicate 1
      AND p.p_discount_active = 'Y'                   -- predicate 2
      AND wp.wp_type = 'Content'                      -- predicate 3
      AND ws.ws_net_paid_inc_tax > 100                -- predicate 4
      AND ib.ib_upper_bound <= 200000                -- predicate 5
      AND EXISTS (                                    -- predicate 6 (EXISTS sub‑query)
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
            AND wr2.wr_return_quantity > 2
      )
),
agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_sk,
        COUNT(*) AS cnt_transactions,
        SUM(j.ss_quantity) AS total_quantity,
        AVG(j.ws_net_paid_inc_tax) AS avg_paid_inc_tax,
        MAX(j.avg_site_price) AS max_avg_site_price
    FROM joined j
    JOIN income_band ib
        ON j.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON j.p_promo_sk = p.p_promo_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, p.p_promo_sk
),
final AS (
    SELECT
        a.ib_income_band_sk,
        a.ib_lower_bound,
        a.ib_upper_bound,
        a.p_promo_sk,
        a.cnt_transactions,
        a.total_quantity,
        a.avg_paid_inc_tax,
        a.max_avg_site_price,
        RANK() OVER (ORDER BY a.cnt_transactions DESC) AS transaction_rank,
        l.total_promo_cost
    FROM agg a
    CROSS JOIN LATERAL (
        SELECT SUM(p2.p_cost) AS total_promo_cost
        FROM promotion p2
        WHERE p2.p_promo_sk = a.p_promo_sk
    ) l
    WHERE a.cnt_transactions > 10
)
SELECT *
FROM final
ORDER BY transaction_rank
LIMIT 100
