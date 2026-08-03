/* goal: Identify high‑value customers and promotional performance for afternoon sales, retaining all time‑dimension rows even if no sales exist, and excluding stores located in Texas */
WITH ss_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    RIGHT OUTER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17                     -- afternoon hours
      AND td.t_meal_time = 'Lunch'                     -- lunch period
      AND ss.ss_quantity > 1                           -- at least two units per transaction
      AND ss.ss_net_paid IS NOT NULL                  -- ensure paid amount present
      AND ss.ss_store_sk NOT IN (                      -- anti‑semi‑join: exclude Texas stores
            SELECT s_store_sk
            FROM store
            WHERE s_state = 'TX'
      )
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    i.i_category,
    p.p_promo_name,
    s.s_store_name,
    SUM(ss_joined.ss_net_paid)        AS total_net_paid,
    AVG(ss_joined.ss_net_profit)      AS avg_profit,
    COUNT(DISTINCT ss_joined.ss_item_sk) AS distinct_items_sold,
    MIN(ss_joined.ss_quantity)        AS min_quantity,
    MAX(ss_joined.ss_quantity)        AS max_quantity
FROM ss_joined
JOIN store s
    ON ss_joined.ss_store_sk = s.s_store_sk
JOIN item i
    ON ss_joined.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss_joined.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON ss_joined.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss_joined.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
    ON ss_joined.ss_item_sk = ws.ws_item_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1990          -- target age range
  AND cd.cd_marital_status = 'M'                    -- married customers
  AND i.i_class = 'fragrances'                      -- specific product class
  AND p.p_discount_active = 'Y'                     -- active promotions
  AND ws.ws_ext_tax > 100                           -- high tax shipments in web channel
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    i.i_category,
    p.p_promo_name,
    s.s_store_name
ORDER BY total_net_paid DESC
LIMIT 100
